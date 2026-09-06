import 'package:btc_horizon/models/cycle_timing_chart_point_model.dart';
import 'package:btc_horizon/models/halving_cycle_model.dart';

class CycleTimingComparisonModel {
  final double currentProgress;
  final List<CycleTimingComparisonItemModel> comparisons;
  final List<CycleTimingChartPointModel> chartPoints;

  const CycleTimingComparisonModel({
    required this.currentProgress,
    required this.comparisons,
    required this.chartPoints,
  });
}

class CycleTimingComparisonItemModel {
  final HalvingCycleModel cycle;
  final DateTime equivalentDate;
  final double closePrice;

  const CycleTimingComparisonItemModel({
    required this.cycle,
    required this.equivalentDate,
    required this.closePrice,
  });
}
