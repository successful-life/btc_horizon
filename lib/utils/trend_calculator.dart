import 'package:btc_horizon/enums/ma_position.dart';
import 'package:btc_horizon/models/binance_kline_model.dart';

List<double?> calculateSma({required List<BinanceKlineModel> klines, required int period}) {
  if (period <= 0) {
    throw ArgumentError('period는 1 이상이어야 합니다.');
  }

  if (klines.length < period) {
    return List<double?>.filled(klines.length, null);
  }

  final smaValues = List<double?>.filled(klines.length, null);

  // 첫 Window 합 계산
  double windowSum = 0;
  for (int i = 0; i < period; i++) {
    windowSum += klines[i].close;
  }

  smaValues[period - 1] = windowSum / period;

  // Sliding Window
  for (int i = period; i < klines.length; i++) {
    windowSum += klines[i].close;
    windowSum -= klines[i - period].close;

    smaValues[i] = windowSum / period;
  }

  return smaValues;
}

double calculateDifferencePercent({required double currentPrice, required double movingAverage}) {
  return ((currentPrice - movingAverage) / movingAverage) * 100;
}

/// 특정 이동평균선(MA) 기준 현재 가격의 위치 및 근접도를 6단계로 분석하여 추세 점수를 계산합니다. (임시)
MaPosition calculateMaPositionStatus({
  required double currentPrice,
  required double maValue,
  double nearThresholdPercent = 0.03, // 근접 버퍼 (기본값 3%)
  double extremeThresholdPercent = 0.3, // 과열/투매 버퍼 (기본값 30%)
}) {
  // 1. 과열 및 근접 밴드(한계선) 계산
  double extremeUpperBand = maValue * (1 + extremeThresholdPercent);
  double nearUpperBand = maValue * (1 + nearThresholdPercent);

  double nearLowerBand = maValue * (1 - nearThresholdPercent);
  double extremeLowerBand = maValue * (1 - extremeThresholdPercent);

  if (currentPrice > extremeUpperBand) {
    // 상태 1: 과매수/과열 (이평선과 지나치게 멀어짐, FOMO 구간)
    return MaPosition.extremeAbove;
  } else if (currentPrice > nearUpperBand) {
    // 상태 2: 이평선 위
    return MaPosition.above;
  } else if (currentPrice > maValue) {
    // 상태 3: 이평 상단 근접
    return MaPosition.nearAbove;
  } else if (currentPrice >= nearLowerBand) {
    // 상태 4: 이평 하단 근접
    return MaPosition.nearBelow;
  } else if (currentPrice >= extremeLowerBand) {
    // 상태 5: 이평선 아래
    return MaPosition.below;
  } else {
    // 상태 6: 과매도/투매 (이평선과 지나치게 멀어짐, 패닉셀 구간)
    return MaPosition.extremeBelow;
  }
}

double getMaPositionScore({required MaPosition maPosition}) {
  return switch (maPosition) {
    MaPosition.extremeAbove => 95,
    MaPosition.above => 75,
    MaPosition.nearAbove => 55,
    MaPosition.nearBelow => 45,
    MaPosition.below => 25,
    MaPosition.extremeBelow => 5,
  };
}

String getMaPositionDescription({required MaPosition maPosition}) {
  return switch (maPosition) {
    MaPosition.extremeAbove => '1년 이평선 위로 매우 멀어진 상태',
    MaPosition.above => '1년 이평선 위로 멀어진 상태',
    MaPosition.nearAbove => '1년 이평선보다 약간 위에 있는 상태',
    MaPosition.nearBelow => '1년 이평선보다 약간 아래에 있는 상태',
    MaPosition.below => '1년 이평선 아래로 멀어진 상태',
    MaPosition.extremeBelow => '1년 이평선 아래로 매우 멀어진 상태',
  };
}
