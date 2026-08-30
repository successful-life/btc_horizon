class BitstampOhlcModel {
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;

  const BitstampOhlcModel({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory BitstampOhlcModel.fromJson(Map<String, dynamic> json) {
    return BitstampOhlcModel(
      openTime: DateTime.fromMillisecondsSinceEpoch(
        int.parse(json['timestamp'] as String) * 1000,
        isUtc: true,
      ),
      open: double.parse(json['open'] as String),
      high: double.parse(json['high'] as String),
      low: double.parse(json['low'] as String),
      close: double.parse(json['close'] as String),
    );
  }
}
