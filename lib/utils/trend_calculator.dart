import 'package:btc_horizon/enums/trend_status.dart';
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

List<double?> calculateEma({required List<BinanceKlineModel> klines, required int period}) {
  if (period <= 0) {
    throw ArgumentError('period는 1 이상이어야 합니다.');
  }

  if (klines.length < period) {
    return List<double?>.filled(klines.length, null);
  }

  final emaValues = List<double?>.filled(klines.length, null);

  // EMA smoothing factor
  final alpha = 2 / (period + 1);

  // 첫 EMA는 SMA로 초기화
  double initialSum = 0;

  for (int i = 0; i < period; i++) {
    initialSum += klines[i].close;
  }

  emaValues[period - 1] = initialSum / period;

  // 이후 EMA 계산
  for (int i = period; i < klines.length; i++) {
    final previousEma = emaValues[i - 1]!;

    emaValues[i] = (klines[i].close * alpha) + (previousEma * (1 - alpha));
  }

  return emaValues;
}

List<double?> calculateSsma({required List<BinanceKlineModel> klines, required int period}) {
  if (period <= 0) {
    throw ArgumentError('period는 1 이상이어야 합니다.');
  }

  if (klines.length < period) {
    return List<double?>.filled(klines.length, null);
  }

  final ssmaValues = List<double?>.filled(klines.length, null);

  // 첫 번째 SSMA는 SMA로 초기화
  double initialSum = 0;

  for (int i = 0; i < period; i++) {
    initialSum += klines[i].close;
  }

  ssmaValues[period - 1] = initialSum / period;

  // 이후부터 이전 SSMA를 이용해 계산
  for (int i = period; i < klines.length; i++) {
    final previousSsma = ssmaValues[i - 1]!;

    ssmaValues[i] = ((previousSsma * (period - 1)) + klines[i].close) / period;
  }

  return ssmaValues;
}

double calculateDifferencePercent({required double currentPrice, required double movingAverage}) {
  return ((currentPrice - movingAverage) / movingAverage) * 100;
}

TrendStatus calculateTrendStatus({
  required double currentBtcPrice,
  required double upperTrendThreshold,
  required double trendBaseline,
  required double lowerTrendThreshold,
  required double bottomRangeBoundary,
}) {
  // 52W 기준선 주변의 전환 구간
  const centerBuffer = 0.015; // 1.5%

  // 52W 기준선 중심 버퍼
  final centerRangeTop = trendBaseline * (1 + centerBuffer);
  final centerRangeBottom = trendBaseline * (1 - centerBuffer);

  // ========================================
  // 1. 상승 추세 영역
  // ========================================
  if (currentBtcPrice > centerRangeTop) {
    // 상단 기준선까지 상회
    if (currentBtcPrice >= upperTrendThreshold) {
      return TrendStatus.veryBullish;
    }

    // 52W 기준선은 상회하지만
    // 상단 기준선까지는 도달하지 못한 상태
    return TrendStatus.bullish;
  }

  // ========================================
  // 2. 하락 추세 영역
  // ========================================
  if (currentBtcPrice < centerRangeBottom) {
    // 아직 하락 깊이 기준선까지 내려가지 않음
    if (currentBtcPrice >= lowerTrendThreshold) {
      return TrendStatus.bearish;
    }

    // 하락 깊이 기준선은 하회했지만
    // 바닥권 기준선까지는 내려가지 않음
    if (currentBtcPrice >= bottomRangeBoundary) {
      return TrendStatus.deepBearish;
    }

    // 바닥권 기준선 이하
    return TrendStatus.bottomRange;
  }

  // ========================================
  // 3. 52W 기준선 부근
  // ========================================
  return TrendStatus.transition;
}
