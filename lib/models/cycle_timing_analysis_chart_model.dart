import 'package:btc_horizon/models/cycle_timing_analysis_model.dart';
import 'package:btc_horizon/models/cycle_timing_chart_point_model.dart';
import 'package:btc_horizon/models/cycle_timing_interval_model.dart';

class CycleTimingAnalysisChartModel {
  final CycleTimingAnalysisModel analysis;
  final List<CycleTimingChartPointModel> pricePoints;
  final List<CycleTimingIntervalModel> topToTopIntervals;
  final List<CycleTimingIntervalModel> bottomToBottomIntervals;

  CycleTimingAnalysisChartModel({
    required this.analysis,
    required List<CycleTimingChartPointModel> pricePoints,
    required List<CycleTimingIntervalModel> topToTopIntervals,
    required List<CycleTimingIntervalModel> bottomToBottomIntervals,
  }) : pricePoints = List.unmodifiable(pricePoints),
       topToTopIntervals = List.unmodifiable(topToTopIntervals),
       bottomToBottomIntervals = List.unmodifiable(bottomToBottomIntervals);
}
