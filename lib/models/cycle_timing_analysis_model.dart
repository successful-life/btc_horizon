import 'package:btc_horizon/models/cycle_timing_estimate_model.dart';
import 'package:btc_horizon/models/cycle_timing_interval_model.dart';

class CycleTimingAnalysisModel {
  final DateTime asOfDate;
  final List<CycleTimingIntervalModel> topToBottomIntervals;
  final List<CycleTimingIntervalModel> bottomToTopIntervals;
  final int averageTopToBottomDays;
  final int averageBottomToTopDays;
  final CycleTimingEstimateModel targetEstimate;
  final String status;
  final double? score;

  CycleTimingAnalysisModel({
    required this.asOfDate,
    required this.topToBottomIntervals,
    required this.bottomToTopIntervals,
    required this.averageTopToBottomDays,
    required this.averageBottomToTopDays,
    required this.targetEstimate,
    required this.status,
    this.score,
  });
}
