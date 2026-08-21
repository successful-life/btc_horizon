import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';

class CycleIndicatorModel {
  final CycleIndicatorType type;
  final String title;
  final double? score;
  final double weight;
  final List<IndicatorSummaryModel> indicators;

  const CycleIndicatorModel({
    required this.type,
    required this.title,
    this.score,
    required this.weight,
    required this.indicators,
  });
}
