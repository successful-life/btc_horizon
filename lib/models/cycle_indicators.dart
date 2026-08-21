import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/trend_detail_model.dart';

class CycleIndicators {
  final CycleIndicatorModel valuation;
  final CycleIndicatorModel cycleTiming;
  final TrendDetailModel trend;
  final CycleIndicatorModel sentiment;

  CycleIndicators({
    required this.valuation,
    required this.cycleTiming,
    required this.trend,
    required this.sentiment,
  });
}
