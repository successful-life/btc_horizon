import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';

class CycleTimingEstimateModel {
  final CycleTimingEstimateType type;
  final DateTime centerDate;
  final DateTime rangeStartDate;
  final DateTime rangeEndDate;

  const CycleTimingEstimateModel({
    required this.type,
    required this.centerDate,
    required this.rangeStartDate,
    required this.rangeEndDate,
  });
}
