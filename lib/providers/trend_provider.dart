import 'package:btc_horizon/enums/binance_symbol.dart';
import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:btc_horizon/models/trend_detail_model.dart';
import 'package:btc_horizon/providers/binance_price_provider.dart';
import 'package:btc_horizon/providers/weekly_trend_data_provider.dart';
import 'package:btc_horizon/utils/trend_calculator.dart';
import 'package:btc_horizon/utils/trend_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trendProvider = Provider.family<AsyncValue<TrendDetailModel>, double>((ref, trendWeight) {
  print('⚡ trendProvider 실행');
  final weeklyTrendDataAsync = ref.watch(weeklyTrendDataProvider);
  final btcPriceAsync = ref.watch(binancePriceProvider(BinanceSymbol.btcusdt));

  // 1. Error
  if (weeklyTrendDataAsync.hasError) {
    return AsyncError(weeklyTrendDataAsync.error!, weeklyTrendDataAsync.stackTrace!);
  }

  if (btcPriceAsync.hasError) {
    return AsyncError(btcPriceAsync.error!, btcPriceAsync.stackTrace!);
  }

  // 2. Loading
  if (!weeklyTrendDataAsync.hasValue || !btcPriceAsync.hasValue) {
    return const AsyncLoading();
  }

  // 3. Data
  final weeklyTrendData = weeklyTrendDataAsync.requireValue;
  final btcPrice = btcPriceAsync.requireValue;

  final trendBaseline = weeklyTrendData.trendBaseline;
  final upperTrendThreshold = weeklyTrendData.upperTrendThreshold;
  final lowerTrendThreshold = weeklyTrendData.lowerTrendThreshold;
  final bottomRangeBoundary = weeklyTrendData.bottomRangeBoundary;

  final trendBaselineDeviationPercent = calculateDifferencePercent(
    currentPrice: btcPrice,
    movingAverage: trendBaseline,
  );
  final upperTrendThresholdDeviationPercent = calculateDifferencePercent(
    currentPrice: btcPrice,
    movingAverage: upperTrendThreshold,
  );
  final lowerTrendThresholdDeviationPercent = calculateDifferencePercent(
    currentPrice: btcPrice,
    movingAverage: lowerTrendThreshold,
  );
  final bottomRangeBoundaryDeviationPercent = calculateDifferencePercent(
    currentPrice: btcPrice,
    movingAverage: bottomRangeBoundary,
  );

  final trendStatus = calculateTrendStatus(
    currentBtcPrice: btcPrice,
    trendBaseline: trendBaseline,
    upperTrendThreshold: upperTrendThreshold,
    lowerTrendThreshold: lowerTrendThreshold,
    bottomRangeBoundary: bottomRangeBoundary,
  );

  final trendBaselineIndicator = IndicatorSummaryModel(
    label: '장기 추세 기준선',
    value: '${trendBaselineDeviationPercent.toStringAsFixed(2)}%',
    score: null,
    status: getPriceRelationStatus(trendBaselineDeviationPercent),
  );

  final upperTrendThresholdIndicator = IndicatorSummaryModel(
    label: '중·단기 상승 추세선',
    value: '${upperTrendThresholdDeviationPercent.toStringAsFixed(2)}%',
    score: null,
    status: getPriceRelationStatus(upperTrendThresholdDeviationPercent),
  );

  final lowerTrendThresholdIndicator = IndicatorSummaryModel(
    label: '하락 깊이 기준선',
    value: '${lowerTrendThresholdDeviationPercent.toStringAsFixed(2)}%',
    score: null,
    status: getPriceRelationStatus(lowerTrendThresholdDeviationPercent),
  );

  final bottomRangeBoundaryIndicator = IndicatorSummaryModel(
    label: '장기 저점 영역 기준선',
    value: '${bottomRangeBoundaryDeviationPercent.toStringAsFixed(2)}%',
    score: null,
    status: getPriceRelationStatus(bottomRangeBoundaryDeviationPercent),
  );

  final trendModel = CycleIndicatorModel(
    type: CycleIndicatorType.trend,
    title: '추세',
    score: trendStatus.score,
    weight: trendWeight,
    indicators: [
      trendBaselineIndicator,
      upperTrendThresholdIndicator,
      lowerTrendThresholdIndicator,
      bottomRangeBoundaryIndicator,
    ],
  );

  return AsyncData(TrendDetailModel(summary: trendModel, chartData: weeklyTrendData.chartData));
});
