import 'package:btc_horizon/enums/binance_symbol.dart';
import 'package:btc_horizon/models/binance_kline_request_model.dart';
import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/cycle_indicators.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:btc_horizon/models/weighted_score_model.dart';
import 'package:btc_horizon/providers/binance_kline_provider.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/providers/funding_rate_provider.dart';
import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:btc_horizon/utils/trend_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/enums/binance_interval.dart';
import 'package:btc_horizon/providers/binance_price_provider.dart';

const kValuationWeight = 0.4;
const kCycleTimingWeight = 0.3;
const kTrendWeight = 0.15;
const kSentimentWeight = 0.15;

final cycleIndicatorProvider = Provider<CycleIndicators>((ref) {
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
  const weeklyRequest = BinanceKlineRequestModel(
    symbol: BinanceSymbol.btcusdt,
    interval: BinanceKlineInterval.oneWeek,
    limit: 2500,
  );
  const monthlyRequest = BinanceKlineRequestModel(
    symbol: BinanceSymbol.btcusdt,
    interval: BinanceKlineInterval.oneMonth,
    limit: 500,
  );
  final weeklyBtcKlineAsync = ref.watch(binanceKlineProvider(weeklyRequest));
  final monthlyBtcKlineAsync = ref.watch(binanceKlineProvider(monthlyRequest));
  final btcPriceAsync = ref.watch(binancePriceProvider(BinanceSymbol.btcusdt));
  final IndicatorSummaryModel trendIndicator;

  if (weeklyBtcKlineAsync.isLoading || monthlyBtcKlineAsync.isLoading || btcPriceAsync.isLoading) {
    trendIndicator = const IndicatorSummaryModel(
      label: '1년 이평선과의 거리',
      value: '로딩 중...',
      score: null,
      status: null,
    );
  } else if (weeklyBtcKlineAsync.hasError ||
      monthlyBtcKlineAsync.hasError ||
      btcPriceAsync.hasError) {
    trendIndicator = const IndicatorSummaryModel(
      label: '1년 이평선과의 거리',
      value: '에러 발생',
      score: null,
      status: null,
    );
  } else {
    final weeklyBtcKlines = weeklyBtcKlineAsync.requireValue;
    final monthlyBtcKlines = monthlyBtcKlineAsync.requireValue;
    final btcPrice = btcPriceAsync.requireValue;

    final weeklySmaValues = calculateSma(klines: weeklyBtcKlines, period: 52);
    final weeklyEmaValues = calculateEma(klines: weeklyBtcKlines, period: 10);
    final monthlyEmaValues = calculateEma(klines: monthlyBtcKlines, period: 57);

    final weeklySma52 = weeklySmaValues.last!;
    final weeklyEma10 = weeklyEmaValues.last!;
    final monthlyEma57 = monthlyEmaValues.last!;

    final weeklySma52DeviationPercent = calculateDifferencePercent(
      currentPrice: btcPrice,
      movingAverage: weeklySma52,
    );

    final trendStatus = calculateTrendStatus(
      currentBtcPrice: btcPrice,
      trendBaseline: weeklySma52,
      upperTrendBoundary: weeklyEma10,
      lowerTrendBoundary: monthlyEma57,
    );

    trendIndicator = IndicatorSummaryModel(
      label: '1년 이평선과의 거리',
      value: '${weeklySma52DeviationPercent.toStringAsFixed(2)}%',
      score: trendStatus.score,
      status: trendStatus.description,
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
    title: '가치평가',
    score: valuationScore,
    weight: kValuationWeight,
    indicators: [mvrvIndicator],
  );

  final cycleTimingModel = CycleIndicatorModel(
    title: '사이클 타이밍',
    score: cycleTimingScore,
    weight: kCycleTimingWeight,
    indicators: [timingRangeIndicator],
  );

  final trendModel = CycleIndicatorModel(
    title: '추세',
    score: trendScore,
    weight: kTrendWeight,
    indicators: [trendIndicator],
  );

  final sentimentModel = CycleIndicatorModel(
    title: '심리/레버리지',
    score: sentimentScore,
    weight: kSentimentWeight,
    indicators: [fearGreedIndicator, fundingRateIndicator],
  );

  return CycleIndicators(
    valuation: valuationModel,
    cycleTiming: cycleTimingModel,
    trend: trendModel,
    sentiment: sentimentModel,
  );
});
