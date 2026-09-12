import 'package:btc_horizon/data/cycle_timing_data.dart';
import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';
import 'package:btc_horizon/models/cycle_indicators.dart';
import 'package:btc_horizon/models/cycle_timing_analysis_model.dart';
import 'package:btc_horizon/models/cycle_timing_estimate_model.dart';
import 'package:btc_horizon/models/cycle_timing_interval_model.dart';
import 'package:btc_horizon/models/weighted_score_model.dart';
import 'dart:math' as math;

const kCycleTolerance = Duration(days: 50);
const kWeightTolerance = 0.001;

// ================================
// 1. Valuation & On-chain
// ================================

// 1-1. MVRV Z-Score
double calculateMvrvScore(double mvrvZScore) {
  if (mvrvZScore >= 7.0) return 100;
  if (mvrvZScore >= 6.5) return 97;
  if (mvrvZScore >= 6.0) return 95;
  if (mvrvZScore >= 5.5) return 92;
  if (mvrvZScore >= 5.0) return 88;
  if (mvrvZScore >= 4.5) return 84;
  if (mvrvZScore >= 4.0) return 80;
  if (mvrvZScore >= 3.5) return 75;
  if (mvrvZScore >= 3.0) return 70;
  if (mvrvZScore >= 2.5) return 65;
  if (mvrvZScore >= 2.0) return 60;
  if (mvrvZScore >= 1.75) return 55;
  if (mvrvZScore >= 1.5) return 50;
  if (mvrvZScore >= 1.25) return 45;
  if (mvrvZScore >= 1.0) return 40;
  if (mvrvZScore >= 0.75) return 35;
  if (mvrvZScore >= 0.5) return 30;
  if (mvrvZScore >= 0.35) return 25;
  if (mvrvZScore >= 0.2) return 20;
  if (mvrvZScore >= 0.0) return 15;
  if (mvrvZScore >= -0.2) return 10;
  if (mvrvZScore >= -0.4) return 5;
  return 0;
}

String getMvrvStatus(double mvrvZScore) {
  if (mvrvZScore >= 6) return '역사적 과열';
  if (mvrvZScore >= 4) return '과열';
  if (mvrvZScore >= 3) return '과열 진입';
  if (mvrvZScore >= 2) return '상승 중반';
  if (mvrvZScore >= 1) return '중립';
  if (mvrvZScore >= 0) return '저평가';
  return '극단적 저평가';
}

// ================================
// 2. Cycle Timing
// ================================
bool isWithinRange({required DateTime date, required DateTime start, required DateTime end}) =>
    !date.isBefore(start) && date.isBefore(end); // [start, end)

double calculateRangeScore({
  required DateTime date,
  required DateTime rangeStart,
  required DateTime rangeEnd,
  required int centerScore,
  required int edgeScore,
}) {
  final totalDays = rangeEnd.difference(rangeStart).inDays;

  if (totalDays <= 0) {
    throw ArgumentError('rangeEnd는 rangeStart보다 이후여야 합니다.');
  }

  final centerDate = rangeStart.add(Duration(days: totalDays ~/ 2));

  final halfRangeDays = totalDays / 2;

  final distanceDays = date.difference(centerDate).inDays.abs();

  final distanceRatio = (distanceDays / halfRangeDays).clamp(0.0, 1.0);

  final int stepCount;

  const double centerZoneRatio = 0.15;
  const double nearCenterZoneRatio = 0.35;
  const double middleZoneRatio = 0.60;
  const double edgeZoneRatio = 0.85;

  // 예상 중심으로부터 범위 반경 대비 거리
  // 0~15%: 중심 점수
  // 15~35%: 1단계
  // 35~60%: 2단계
  // 60~85%: 3단계
  // 85~100%: 경계 점수
  if (distanceRatio <= centerZoneRatio) {
    stepCount = 0;
  } else if (distanceRatio <= nearCenterZoneRatio) {
    stepCount = 1;
  } else if (distanceRatio <= middleZoneRatio) {
    stepCount = 2;
  } else if (distanceRatio <= edgeZoneRatio) {
    stepCount = 3;
  } else {
    stepCount = 4;
  }

  final stepProgress = stepCount / 4;

  final score = centerScore + (edgeScore - centerScore) * stepProgress;

  return score.clamp(math.min(centerScore, edgeScore), math.max(centerScore, edgeScore)).toDouble();
}

double calculateTransitionScore({
  required DateTime date,
  required DateTime startDate,
  required DateTime endDate,
  required int startScore,
  required int endScore,
}) {
  final totalDays = endDate.difference(startDate).inDays;

  if (totalDays <= 0) {
    throw ArgumentError('endDate는 startDate보다 이후여야 합니다.');
  }

  final elapsedDaysFromStart = date.difference(startDate).inDays;

  final progress = (elapsedDaysFromStart / totalDays).clamp(0.0, 1.0);

  return (startScore + (endScore - startScore) * progress);
}

// 2-1. 날짜 기반 예측
CycleTimingAnalysisModel calculateCycleTimingAnalysis({required DateTime today}) {
  final bottomToTopIntervals = <CycleTimingIntervalModel>[];
  final topToBottomIntervals = <CycleTimingIntervalModel>[];

  final bottomToTopCount = math.min(btcCycleBottoms.length, btcCycleTops.length);

  for (int i = 0; i < bottomToTopCount; i++) {
    final startDate = btcCycleBottoms[i];
    final endDate = btcCycleTops[i];

    if (!endDate.isAfter(startDate)) {
      throw ArgumentError('고점 날짜는 대응하는 저점 날짜보다 이후여야 합니다.');
    }

    bottomToTopIntervals.add(CycleTimingIntervalModel(startDate: startDate, endDate: endDate));
  }

  for (int i = 0; i < btcCycleTops.length && i + 1 < btcCycleBottoms.length; i++) {
    final startDate = btcCycleTops[i];
    final endDate = btcCycleBottoms[i + 1];

    if (!endDate.isAfter(startDate)) {
      throw ArgumentError('다음 저점 날짜는 고점 날짜보다 이후여야 합니다.');
    }

    topToBottomIntervals.add(CycleTimingIntervalModel(startDate: startDate, endDate: endDate));
  }

  // 저->고, 고->저 평균 구하기
  if (bottomToTopIntervals.isEmpty) {
    throw ArgumentError('완성된 저점 → 고점 구간이 없습니다.');
  }

  if (topToBottomIntervals.isEmpty) {
    throw ArgumentError('완성된 고점 → 저점 구간이 없습니다.');
  }

  final bottomToTopTotalDays = bottomToTopIntervals.fold<int>(
    0,
    (sum, interval) => sum + interval.durationDays,
  );

  final topToBottomTotalDays = topToBottomIntervals.fold<int>(
    0,
    (sum, interval) => sum + interval.endDate.difference(interval.startDate).inDays,
  );

  final averageBottomToTopDays = (bottomToTopTotalDays / bottomToTopIntervals.length).round();
  final averageTopToBottomDays = (topToBottomTotalDays / topToBottomIntervals.length).round();

  final topEstimateCenterDate = btcCycleBottoms.last.add(Duration(days: averageBottomToTopDays));
  final bottomEstimateCenterDate = btcCycleTops.last.add(Duration(days: averageTopToBottomDays));

  final topEstimate = CycleTimingEstimateModel(
    type: CycleTimingEstimateType.top,
    centerDate: topEstimateCenterDate,
    rangeStartDate: topEstimateCenterDate.subtract(kCycleTolerance),
    rangeEndDate: topEstimateCenterDate.add(kCycleTolerance),
  );

  final bottomEstimate = CycleTimingEstimateModel(
    type: CycleTimingEstimateType.bottom,
    centerDate: bottomEstimateCenterDate,
    rangeStartDate: bottomEstimateCenterDate.subtract(kCycleTolerance),
    rangeEndDate: bottomEstimateCenterDate.add(kCycleTolerance),
  );

  final targetEstimate = btcCycleTops.last.isAfter(btcCycleBottoms.last)
      ? bottomEstimate
      : topEstimate;
  final String status;
  final double? score;

  const int bottomCenterScore = 0;
  const int bottomEdgeScore = 20;
  const int topEdgeScore = 80;
  const int topCenterScore = 100;

  // 고점 내부라면
  if (isWithinRange(
    date: today,
    start: topEstimate.rangeStartDate,
    end: topEstimate.rangeEndDate,
  )) {
    status = '예상 고점 범위';
    score = calculateRangeScore(
      date: today,
      rangeStart: topEstimate.rangeStartDate,
      rangeEnd: topEstimate.rangeEndDate,
      centerScore: topCenterScore,
      edgeScore: topEdgeScore,
    );
  }
  // 저점 내부라면
  else if (isWithinRange(
    date: today,
    start: bottomEstimate.rangeStartDate,
    end: bottomEstimate.rangeEndDate,
  )) {
    status = '예상 저점 범위';
    score = calculateRangeScore(
      date: today,
      rangeStart: bottomEstimate.rangeStartDate,
      rangeEnd: bottomEstimate.rangeEndDate,
      centerScore: bottomCenterScore,
      edgeScore: bottomEdgeScore,
    );
  }
  // 고점으로 가는 중이라면 (저점 지남)
  else if (isWithinRange(
    date: today,
    start: bottomEstimate.rangeEndDate,
    end: topEstimate.rangeStartDate,
  )) {
    status = '저점 이후 · 고점 접근';
    score = calculateTransitionScore(
      date: today,
      startDate: bottomEstimate.rangeEndDate,
      endDate: topEstimate.rangeStartDate,
      startScore: bottomEdgeScore,
      endScore: topEdgeScore,
    );
  }
  // 저점으로 가는 중이라면 (고점 지남)
  else if (isWithinRange(
    date: today,
    start: topEstimate.rangeEndDate,
    end: bottomEstimate.rangeStartDate,
  )) {
    status = '고점 이후 · 저점 접근';
    score = calculateTransitionScore(
      date: today,
      startDate: topEstimate.rangeEndDate,
      endDate: bottomEstimate.rangeStartDate,
      startScore: topEdgeScore,
      endScore: bottomEdgeScore,
    );
  } else {
    status = '현재 날짜가 예상 범위를 벗어났습니다.';
    score = null;
  }

  return CycleTimingAnalysisModel(
    asOfDate: today,
    topToBottomIntervals: topToBottomIntervals,
    bottomToTopIntervals: bottomToTopIntervals,
    averageTopToBottomDays: averageTopToBottomDays,
    averageBottomToTopDays: averageBottomToTopDays,
    targetEstimate: targetEstimate,
    status: status,
    score: score,
  );
}

// ================================
// 4. Sentiment
// ================================

// 4-1. Funding Rate
double calculateFundingRateScore(double fundingRatePercent) {
  if (fundingRatePercent >= 0.16) return 100;
  if (fundingRatePercent >= 0.14) return 90;
  if (fundingRatePercent >= 0.10) return 80;
  if (fundingRatePercent >= 0.06) return 70;
  if (fundingRatePercent >= 0.03) return 60;
  if (fundingRatePercent >= 0.01) return 55;
  if (fundingRatePercent >= 0.00) return 50;
  if (fundingRatePercent >= -0.01) return 45;
  if (fundingRatePercent >= -0.03) return 35;
  if (fundingRatePercent >= -0.05) return 20;
  return 10;
}

String getFundingRateStatus(double fundingRatePercent) {
  if (fundingRatePercent >= 0.16) return '극단적 롱 과열';
  if (fundingRatePercent >= 0.10) return '롱 과열';
  if (fundingRatePercent >= 0.06) return '롱 우세';
  if (fundingRatePercent >= 0.03) return '약한 롱 우세';
  if (fundingRatePercent >= 0.01) return '중립 상단';
  if (fundingRatePercent >= 0.00) return '중립';
  if (fundingRatePercent >= -0.01) return '중립 하단';
  if (fundingRatePercent >= -0.03) return '약한 숏 우세';
  if (fundingRatePercent >= -0.05) return '숏 우세';
  return '극단적 숏 쏠림';
}

// 4-2. Fear & Greed
String getFearGreedStatus(double fearGreedValue) {
  if (fearGreedValue >= 75) return '극단적 탐욕';
  if (fearGreedValue >= 55) return '탐욕';
  if (fearGreedValue >= 45) return '중립';
  if (fearGreedValue >= 25) return '공포';
  return '극단적 공포';
}

// ================================
// 각 카테고리 최종 점수 계산
// ================================
// 모든 지표의 score가 정상적으로 존재할 때만 카테고리 점수를 계산한다.
// 각 카테고리의 weight 합은 1.0이 되도록 구성한다.
double? calculateCategoryScore({required List<WeightedScore> indicatorList}) {
  if (indicatorList.isEmpty) return null;

  double score = 0;
  double totalWeight = 0;

  for (final item in indicatorList) {
    if (item.score == null) return null;

    score += (item.score! * item.weight);
    totalWeight += item.weight;
  }

  if ((totalWeight - 1.0).abs() > kWeightTolerance) return null;

  return score;
}

double? calculateCyclePositionScore({required CycleIndicators indicators}) {
  final valuationScore = indicators.valuation.score;
  final cycleTimingScore = indicators.cycleTiming.score;
  final trendScore = indicators.trend.summary.score;
  final sentimentScore = indicators.sentiment.score;

  if (valuationScore == null ||
      cycleTimingScore == null ||
      trendScore == null ||
      sentimentScore == null) {
    return null;
  }

  final cyclePositionScore =
      valuationScore * indicators.valuation.weight +
      cycleTimingScore * indicators.cycleTiming.weight +
      trendScore * indicators.trend.summary.weight +
      sentimentScore * indicators.sentiment.weight;

  return cyclePositionScore.clamp(0.0, 100.0).toDouble();
}

String getCyclePositionLabel({required double cyclePositionScore}) {
  return switch (cyclePositionScore) {
    >= 81 => '고점 근접',
    >= 61 => '후반 상승 구간',
    >= 41 => '사이클 중립',
    >= 21 => '저평가 진입',
    _ => '저점 근접',
  };
}

String getCyclePositionDescription({required double cyclePositionScore}) {
  return switch (cyclePositionScore) {
    >= 81 =>
      '시장 사이클 기준으로 고점에 가까운 위치입니다.\n'
          '과거에는 이 구간 이후 변동성이 확대되는 사례가 많았습니다.',

    >= 61 =>
      '상승 사이클 후반부로 진입한 상태입니다.\n'
          '추가 상승 가능성과 함께 변동성도 커질 수 있습니다.',

    >= 41 =>
      '시장은 현재 사이클의 중간 수준에 위치해 있습니다.\n'
          '뚜렷한 고점이나 저점 신호는 아직 확인되지 않습니다.',

    >= 21 =>
      '시장 사이클 기준으로 저평가 영역에 가까워지고 있습니다.\n'
          '과거에는 장기적인 회복이 시작된 사례가 많았습니다.',

    _ =>
      '시장 사이클 기준으로 저점에 가까운 위치입니다.\n'
          '장기 투자자들의 관심이 높아지는 구간으로 평가되곤 했습니다.',
  };
}
