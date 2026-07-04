import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/providers/funding_rate_provider.dart';
import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleIndicatorProvider = Provider<List<CycleIndicatorModel>>((ref) {
  // 1. Valuation & On-chain
  final mvrvAsync = ref.watch(mvrvZScoreProvider);
  final IndicatorSummaryModel mvrvIndicator;

  if (mvrvAsync.isLoading) {
    mvrvIndicator = const IndicatorSummaryModel(
      label: 'MVRV Z-Score',
      value: '로딩 중...',
      score: null,
    );
  } else if (mvrvAsync.hasError) {
    mvrvIndicator = const IndicatorSummaryModel(label: 'MVRV Z-Score', value: '에러 발생', score: null);
  } else {
    final mvrvModel = mvrvAsync.requireValue;

    mvrvIndicator = IndicatorSummaryModel(
      label: 'MVRV Z-Score',
      value: mvrvModel.mvrvZScore.toStringAsFixed(3),
      score: null,
    );
  }

  // 2. Cycle Timing

  // 3. Trend & Momentum

  // 4. Sentiment & Leverage
  final fearGreedAsync = ref.watch(fearGreedProvider);
  final fundingRateAsync = ref.watch(fundingRateProvider);
  final IndicatorSummaryModel fearGreedIndicator;
  final IndicatorSummaryModel fundingRateIndicator;

  // 4-1. 공포탐욕지수
  if (fearGreedAsync.isLoading) {
    fearGreedIndicator = const IndicatorSummaryModel(
      label: 'Fear & Greed',
      value: '로딩 중...',
      score: null,
    );
  } else if (fearGreedAsync.hasError) {
    fearGreedIndicator = const IndicatorSummaryModel(
      label: 'Fear & Greed',
      value: '에러 발생',
      score: null,
    );
  } else {
    final fearGreedModel = fearGreedAsync.requireValue;

    fearGreedIndicator = IndicatorSummaryModel(
      label: 'Fear & Greed',
      value: fearGreedModel.value.toString(),
      score: null,
    );
  }

  // 4-2. 펀딩비
  if (fundingRateAsync.isLoading) {
    fundingRateIndicator = const IndicatorSummaryModel(
      label: 'Funding Rate',
      value: '로딩 중...',
      score: null,
    );
  } else if (fundingRateAsync.hasError) {
    fundingRateIndicator = const IndicatorSummaryModel(
      label: 'Funding Rate',
      value: '에러 발생',
      score: null,
    );
  } else {
    final fundingRateModel = fundingRateAsync.requireValue;

    fundingRateIndicator = IndicatorSummaryModel(
      label: 'Funding Rate',
      value: '${(fundingRateModel.lastFundingRate * 100).toStringAsFixed(5)}%',
      score: null,
    );
  }

  return [
    CycleIndicatorModel(title: '가치평가', weight: 40, indicators: [mvrvIndicator]),
    CycleIndicatorModel(title: '사이클 타이밍', weight: 25, indicators: []),
    CycleIndicatorModel(title: '추세', weight: 20, indicators: []),
    CycleIndicatorModel(
      title: '심리/레버리지',
      weight: 15,
      indicators: [fearGreedIndicator, fundingRateIndicator],
    ),
  ];
});
