import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/cycle_indicators.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:btc_horizon/models/trend_detail_model.dart';
import 'package:btc_horizon/models/weighted_score_model.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/providers/funding_rate_provider.dart';
import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:btc_horizon/providers/trend_provider.dart';
import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const kValuationWeight = 0.35;
const kCycleTimingWeight = 0.3;
const kTrendWeight = 0.25;
const kSentimentWeight = 0.1;

final cycleIndicatorProvider = Provider<CycleIndicators>((ref) {
  final valuationList = <WeightedScore>[];
  final cycleTimingList = <WeightedScore>[];
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
  final trendAsync = ref.watch(trendProvider);

  final TrendDetailModel trendDetailModel;

  if (trendAsync.hasValue) {
    trendDetailModel = trendAsync.requireValue;
  } else {
    trendDetailModel = TrendDetailModel(
      summary: CycleIndicatorModel(
        type: CycleIndicatorType.trend,
        title: '추세',
        score: null,
        weight: kTrendWeight,
        indicators: const [],
      ),
      chartData: const TrendChartDataModel(
        price: [],
        trendBaseline: [],
        upperTrendThreshold: [],
        lowerTrendThreshold: [],
        bottomRangeBoundary: [],
      ),
    );
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
