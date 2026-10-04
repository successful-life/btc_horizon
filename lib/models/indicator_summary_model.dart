class IndicatorSummaryModel {
  final String label;
  final String value;
  final double? score;
  final String? status;
  final DateTime? dataDate;

  const IndicatorSummaryModel({
    required this.label,
    required this.value,
    this.score,
    this.status,
    this.dataDate,
  });
}
