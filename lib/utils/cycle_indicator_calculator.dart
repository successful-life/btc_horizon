import 'package:btc_horizon/models/weighted_score_model.dart';

// ================================
// 1. Valuation & On-chain
// ================================

// 1-1. MVRV Z-Score
int calculateMvrvScore(double mvrvZScore) {
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

// ================================
// 3. Trend & Momentum
// ================================

// ================================
// 4. Sentiment & Leverage
// ================================

// 4-1. Funding Rate
int calculateFundingRateScore(double fundingRatePercent) {
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
String getFearGreedStatus(int fearGreedValue) {
  if (fearGreedValue >= 75) return '극단적 탐욕';
  if (fearGreedValue >= 55) return '탐욕';
  if (fearGreedValue >= 45) return '중립';
  if (fearGreedValue >= 25) return '공포';
  return '극단적 공포';
}

// ================================
// 5. 각 카테고리 최종 점수 계산
// ================================
// 모든 지표의 score가 정상적으로 존재할 때만 카테고리 점수를 계산한다.
// 하나라도 null이면 신뢰도 문제를 피하기 위해 null을 반환한다.
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

  const tolerance = 0.0001;
  if ((totalWeight - 1.0).abs() > tolerance) return null;

  return score;
}
