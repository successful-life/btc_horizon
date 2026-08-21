import 'package:btc_horizon/enums/binance_symbol.dart';
import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/models/binance_kline_request_model.dart';
import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/cycle_indicators.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:btc_horizon/models/trend_detail_model.dart';
import 'package:btc_horizon/models/weighted_score_model.dart';
import 'package:btc_horizon/providers/binance_kline_provider.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/providers/funding_rate_provider.dart';
import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:btc_horizon/utils/trend_calculator.dart';
import 'package:btc_horizon/utils/trend_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/enums/binance_interval.dart';
import 'package:btc_horizon/providers/binance_price_provider.dart';

final cycleIndicatorProvider = Provider<CycleIndicators>((ref) {
  const kValuationWeight = 0.4;
  const kCycleTimingWeight = 0.3;
  const kTrendWeight = 0.15;
  const kSentimentWeight = 0.15;

  final valuationList = <WeightedScore>[];
  final cycleTimingList = <WeightedScore>[];
  final trendList = <WeightedScore>[];
  final sentimentList = <WeightedScore>[];

  // ================================
  // 1. Valuation & On-chain
  // ================================

  // 1-1. MVRV Z-Score

  final mvrvAsync = ref.watch(mvrvZScoreProvider);
  final IndicatorSummaryModel mvrvIndicator;

  if (mvrvAsync.isLoading) {
    mvrvIndicator = const IndicatorSummaryModel(
      label: 'MVRV Z-Score',
      value: '로딩 중...',
      score: null,
      status: null,
    );
  } else if (mvrvAsync.hasError) {
    mvrvIndicator = const IndicatorSummaryModel(
      label: 'MVRV Z-Score',
      value: '에러 발생',
      score: null,
      status: null,
    );
  } else {
    final mvrvModel = mvrvAsync.requireValue;
    final mvrvScore = calculateMvrvScore(mvrvModel.mvrvZScore);
    final mvrvStatus = getMvrvStatus(mvrvModel.mvrvZScore);

    mvrvIndicator = IndicatorSummaryModel(
      label: 'MVRV Z-Score',
      value: mvrvModel.mvrvZScore.toStringAsFixed(2),
      score: mvrvScore,
      status: mvrvStatus,
    );

    valuationList.add(WeightedScore(score: mvrvScore, weight: 1.0));
  }

  // ================================
  // 2. Cycle Timing
  // ================================

  // 2-1. 고점 및 저점 기반 예측
  final now = DateTime.now();
  final timingRangeIndicator = calculateCycleTimingIndicator(today: now);
  cycleTimingList.add(WeightedScore(score: timingRangeIndicator.score, weight: 1.0));

  // ================================
  // 3. Trend
  // ================================
  // 3-1. Kline
  final TrendChartDataModel chartData;
  const emptyChartData = TrendChartDataModel(
    price: [],
    trendBaseline: [],
    upperTrendThreshold: [],
    lowerTrendThreshold: [],
    bottomRangeBoundary: [],
  );

  const weeklyRequest = BinanceKlineRequestModel(
    symbol: BinanceSymbol.btcusdt,
    interval: BinanceKlineInterval.oneWeek,
    limit: 2500,
  );
  final weeklyBtcKlineAsync = ref.watch(binanceKlineProvider(weeklyRequest));
  final btcPriceAsync = ref.watch(binancePriceProvider(BinanceSymbol.btcusdt));
  final IndicatorSummaryModel trendBaselineIndicator,
      upperTrendThresholdIndicator,
      lowerTrendThresholdIndicator,
      bottomRangeBoundaryIndicator;

  if (weeklyBtcKlineAsync.isLoading || btcPriceAsync.isLoading) {
    trendBaselineIndicator = const IndicatorSummaryModel(
      label: '',
      value: '로딩 중...',
      score: null,
      status: null,
    );
    upperTrendThresholdIndicator = const IndicatorSummaryModel(
      label: '중·단기 상승 추세선',
      value: '로딩 중...',
      score: null,
      status: null,
    );
    lowerTrendThresholdIndicator = const IndicatorSummaryModel(
      label: '깊은 하락 영역',
      value: '로딩 중...',
      score: null,
      status: null,
    );
    bottomRangeBoundaryIndicator = const IndicatorSummaryModel(
      label: '장기 저점 영역',
      value: '로딩 중...',
      score: null,
      status: null,
    );

    chartData = emptyChartData;
  } else if (weeklyBtcKlineAsync.hasError || btcPriceAsync.hasError) {
    trendBaselineIndicator = const IndicatorSummaryModel(
      label: '1년 이평선과의 거리',
      value: '에러',
      score: null,
      status: null,
    );
    upperTrendThresholdIndicator = const IndicatorSummaryModel(
      label: '중·단기 추세 기준선',
      value: '에러',
      score: null,
      status: null,
    );
    lowerTrendThresholdIndicator = const IndicatorSummaryModel(
      label: '깊은 하락 영역',
      value: '에러',
      score: null,
      status: null,
    );
    bottomRangeBoundaryIndicator = const IndicatorSummaryModel(
      label: '장기 저점 영역',
      value: '에러',
      score: null,
      status: null,
    );

    chartData = emptyChartData;
  } else {
    final weeklyBtcKlines = weeklyBtcKlineAsync.requireValue;
    final btcPrice = btcPriceAsync.requireValue;

    final trendBaselineValues = calculateSma(klines: weeklyBtcKlines, period: 52);
    final upperTrendThresholdValues = calculateEma(klines: weeklyBtcKlines, period: 10);
    final lowerTrendThresholdValues = calculateSsma(klines: weeklyBtcKlines, period: 100);
    final bottomRangeBoundaryValues = calculateEma(klines: weeklyBtcKlines, period: 280);

    final trendBaseline = trendBaselineValues.last!;
    final upperTrendThreshold = upperTrendThresholdValues.last!;
    final lowerTrendThreshold = lowerTrendThresholdValues.last!;
    final bottomRangeBoundary = bottomRangeBoundaryValues.last!;

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

    trendBaselineIndicator = IndicatorSummaryModel(
      label: '장기 추세 기준선',
      value: '${trendBaselineDeviationPercent.toStringAsFixed(2)}%',
      score: null,
      status: getPriceRelationStatus(trendBaselineDeviationPercent),
    );

    upperTrendThresholdIndicator = IndicatorSummaryModel(
      label: '중·단기 상승 추세선',
      value: '${upperTrendThresholdDeviationPercent.toStringAsFixed(2)}%',
      score: null,
      status: getPriceRelationStatus(upperTrendThresholdDeviationPercent),
    );

    lowerTrendThresholdIndicator = IndicatorSummaryModel(
      label: '하락 깊이 기준선',
      value: '${lowerTrendThresholdDeviationPercent.toStringAsFixed(2)}%',
      score: null,
      status: getPriceRelationStatus(lowerTrendThresholdDeviationPercent),
    );

    bottomRangeBoundaryIndicator = IndicatorSummaryModel(
      label: '장기 저점 영역 기준선',
      value: '${bottomRangeBoundaryDeviationPercent.toStringAsFixed(2)}%',
      score: null,
      status: getPriceRelationStatus(bottomRangeBoundaryDeviationPercent),
    );

    // 2. Chart data
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

    chartData = TrendChartDataModel(
      price: pricePoints,
      trendBaseline: trendBaselinePoints,
      upperTrendThreshold: upperTrendThresholdPoints,
      lowerTrendThreshold: lowerTrendThresholdPoints,
      bottomRangeBoundary: bottomRangeBoundaryPoints,
    );

    trendList.add(WeightedScore(score: trendStatus.score, weight: 1.0));
  }

  // ================================
  // 4. Sentiment
  // ================================
  final fearGreedAsync = ref.watch(fearGreedProvider);
  final fundingRateAsync = ref.watch(fundingRateProvider);
  final IndicatorSummaryModel fearGreedIndicator;
  final IndicatorSummaryModel fundingRateIndicator;

  // 4-1. Fear & Greed
  if (fearGreedAsync.isLoading) {
    fearGreedIndicator = const IndicatorSummaryModel(
      label: 'Fear & Greed',
      value: '로딩 중...',
      score: null,
      status: null,
    );
  } else if (fearGreedAsync.hasError) {
    fearGreedIndicator = const IndicatorSummaryModel(
      label: 'Fear & Greed',
      value: '에러 발생',
      score: null,
      status: null,
    );
  } else {
    final fearGreedModel = fearGreedAsync.requireValue;
    final fearGreedValue = fearGreedModel.value;
    final fearGreedScore = fearGreedValue;
    final fearGreedStatus = getFearGreedStatus(fearGreedValue);

    fearGreedIndicator = IndicatorSummaryModel(
      label: 'Fear & Greed',
      value: fearGreedValue.toString(),
      score: fearGreedScore,
      status: fearGreedStatus,
    );

    sentimentList.add(WeightedScore(score: fearGreedScore, weight: 0.9));
  }

  // 4-2. Funding Rate
  if (fundingRateAsync.isLoading) {
    fundingRateIndicator = const IndicatorSummaryModel(
      label: 'Funding Rate',
      value: '로딩 중...',
      score: null,
      status: null,
    );
  } else if (fundingRateAsync.hasError) {
    fundingRateIndicator = const IndicatorSummaryModel(
      label: 'Funding Rate',
      value: '에러 발생',
      score: null,
      status: null,
    );
  } else {
    final fundingRateModel = fundingRateAsync.requireValue;
    final fundingRatePercent = fundingRateModel.lastFundingRate * 100;
    final fundingRateScore = calculateFundingRateScore(fundingRatePercent);
    final fundingRateStatus = getFundingRateStatus(fundingRatePercent);

    fundingRateIndicator = IndicatorSummaryModel(
      label: 'Funding Rate (BTC)',
      value: '${fundingRatePercent.toStringAsFixed(5)}%',
      score: fundingRateScore,
      status: fundingRateStatus,
    );

    sentimentList.add(WeightedScore(score: fundingRateScore, weight: 0.1));
  }

  // ================================
  // 각 카테고리의 Score값 계산
  // ================================
  final valuationScore = calculateCategoryScore(indicatorList: valuationList);
  final cycleTimingScore = calculateCategoryScore(indicatorList: cycleTimingList);
  final trendScore = calculateCategoryScore(indicatorList: trendList);
  final sentimentScore = calculateCategoryScore(indicatorList: sentimentList);

  final valuationModel = CycleIndicatorModel(
    type: CycleIndicatorType.valuation,
    title: '가치평가',
    score: valuationScore,
    weight: kValuationWeight,
    indicators: [mvrvIndicator],
  );

  final cycleTimingModel = CycleIndicatorModel(
    type: CycleIndicatorType.cycleTiming,
    title: '사이클 타이밍',
    score: cycleTimingScore,
    weight: kCycleTimingWeight,
    indicators: [timingRangeIndicator],
  );

  final trendModel = CycleIndicatorModel(
    type: CycleIndicatorType.trend,
    title: '추세',
    score: trendScore,
    weight: kTrendWeight,
    indicators: [
      trendBaselineIndicator,
      upperTrendThresholdIndicator,
      lowerTrendThresholdIndicator,
      bottomRangeBoundaryIndicator,
    ],
  );
  final trendDetailModel = TrendDetailModel(summary: trendModel, chartData: chartData);

  final sentimentModel = CycleIndicatorModel(
    type: CycleIndicatorType.sentiment,
    title: '심리/레버리지',
    score: sentimentScore,
    weight: kSentimentWeight,
    indicators: [fearGreedIndicator, fundingRateIndicator],
  );

  return CycleIndicators(
    valuation: valuationModel,
    cycleTiming: cycleTimingModel,
    trend: trendDetailModel,
    sentiment: sentimentModel,
  );
});
