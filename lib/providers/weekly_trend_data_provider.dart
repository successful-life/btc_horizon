import 'package:btc_horizon/enums/binance_interval.dart';
import 'package:btc_horizon/enums/binance_symbol.dart';
import 'package:btc_horizon/models/binance_kline_request_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:btc_horizon/models/weekly_trend_data_model.dart';
import 'package:btc_horizon/providers/binance_kline_provider.dart';
import 'package:btc_horizon/utils/trend_calculator.dart';
import 'package:btc_horizon/utils/trend_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weeklyTrendDataProvider = Provider<AsyncValue<WeeklyTrendDataModel>>((ref) {
  const weeklyBtcKlineRequest = BinanceKlineRequestModel(
    symbol: BinanceSymbol.btcusdt,
    interval: BinanceKlineInterval.oneWeek,
    limit: 1000,
  );

  final weeklyBtcKlineAsync = ref.watch(binanceKlineProvider(weeklyBtcKlineRequest));

  return weeklyBtcKlineAsync.when(
    data: (weeklyBtcKlines) {
      if (weeklyBtcKlines.length < 280) {
        return AsyncError(StateError('Trend 계산에 필요한 주봉 데이터가 충족되지 않았습니다.'), StackTrace.current);
      }

      final trendBaselineValues = calculateSma(klines: weeklyBtcKlines, period: 52);
      final upperTrendThresholdValues = calculateEma(klines: weeklyBtcKlines, period: 10);
      final lowerTrendThresholdValues = calculateSsma(klines: weeklyBtcKlines, period: 100);
      final bottomRangeBoundaryValues = calculateEma(klines: weeklyBtcKlines, period: 280);

      final pricePoints = weeklyBtcKlines
          .map((kline) => TrendChartPoint(time: kline.openTime, value: kline.close))
          .toList();

      final trendBaselinePoints = buildTrendChartPoints(
        klines: weeklyBtcKlines,
        values: trendBaselineValues,
      );

      final upperTrendThresholdPoints = buildTrendChartPoints(
        klines: weeklyBtcKlines,
        values: upperTrendThresholdValues,
      );

      final lowerTrendThresholdPoints = buildTrendChartPoints(
        klines: weeklyBtcKlines,
        values: lowerTrendThresholdValues,
      );

      final bottomRangeBoundaryPoints = buildTrendChartPoints(
        klines: weeklyBtcKlines,
        values: bottomRangeBoundaryValues,
      );

      final chartData = TrendChartDataModel(
        price: pricePoints,
        trendBaseline: trendBaselinePoints,
        upperTrendThreshold: upperTrendThresholdPoints,
        lowerTrendThreshold: lowerTrendThresholdPoints,
        bottomRangeBoundary: bottomRangeBoundaryPoints,
      );

      return AsyncData(
        WeeklyTrendDataModel(
          trendBaseline: trendBaselineValues.last!,
          upperTrendThreshold: upperTrendThresholdValues.last!,
          lowerTrendThreshold: lowerTrendThresholdValues.last!,
          bottomRangeBoundary: bottomRangeBoundaryValues.last!,
          chartData: chartData,
        ),
      );
    },

    error: (error, stackTrace) {
      return AsyncError(error, stackTrace);
    },

    loading: () => const AsyncLoading(),
  );
});
