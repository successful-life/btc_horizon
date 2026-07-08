class IndicatorSummaryModel {
  final String label;
  final String value;
  final int? score;
  final String? status;

  const IndicatorSummaryModel({required this.label, required this.value, this.score, this.status});
}
