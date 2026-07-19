class FearGreedModel {
  final double value;
  final String valueClassification;
  final DateTime timestamp;
  final int? timeUntilUpdate; // 리스트 중 최신 항목(첫 번째)에만 존재, 나머지는 null

  FearGreedModel({
    required this.value,
    required this.valueClassification,
    required this.timestamp,
    this.timeUntilUpdate,
  });

  factory FearGreedModel.fromJson(Map<String, dynamic> json) {
    return FearGreedModel(
      value: double.parse(json['value']),
      valueClassification: json['value_classification'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.parse(json['timestamp']) * 1000, // unix timestamp는 초 단위라 *1000
      ),
      timeUntilUpdate: json['time_until_update'] != null
          ? int.parse(json['time_until_update'])
          : null,
    );
  }
}
