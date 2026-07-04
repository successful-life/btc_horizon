import 'package:btc_horizon/models/indicator_summary_model.dart';

class CycleIndicatorModel {
  final String title;
  final int? score;
  final int weight;
  final List<IndicatorSummaryModel> indicators;

  const CycleIndicatorModel({
    required this.title,
    this.score,
    required this.weight,
    required this.indicators,
  });
}
