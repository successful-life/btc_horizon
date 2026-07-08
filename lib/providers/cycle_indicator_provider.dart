import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:btc_horizon/models/weighted_score_model.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/providers/funding_rate_provider.dart';
import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleIndicatorProvider = Provider<List<CycleIndicatorModel>>((ref) {
  final List<WeightedScore> valuationList = [];
  final List<WeightedScore> cycleTimingList = [];
  final List<WeightedScore> trendMomentumList = [];
  final List<WeightedScore> sentimentLeverageList = [];

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

  // ================================
  // 3. Trend & Momentum
  // ================================

  // ================================
  // 4. Sentiment & Leverage
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

    sentimentLeverageList.add(WeightedScore(score: fearGreedValue, weight: 0.8));
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

    sentimentLeverageList.add(WeightedScore(score: fundingRateScore, weight: 0.2));
  }

  // ================================
  // 각 카테고리의 Score값 계산
  // ================================

  final valuationScore = calculateCategoryScore(indicatorList: valuationList);
  final cycleTimingScore;
  final trendMomentScore;
  final sentimentLeverageScore = calculateCategoryScore(indicatorList: sentimentLeverageList);

  return [
    CycleIndicatorModel(
      title: '가치평가',
      score: valuationScore,
      weight: 40,
      indicators: [mvrvIndicator],
    ),
    CycleIndicatorModel(title: '사이클 타이밍', score: null, weight: 25, indicators: []),
    CycleIndicatorModel(title: '추세', score: null, weight: 20, indicators: []),
    CycleIndicatorModel(
      title: '심리/레버리지',
      score: sentimentLeverageScore,
      weight: 15,
      indicators: [fearGreedIndicator, fundingRateIndicator],
    ),
  ];
});
