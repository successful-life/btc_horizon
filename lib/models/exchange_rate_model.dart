class ExchangeRateModel {
  final double krw;
  final DateTime nextUpdate;

  ExchangeRateModel({required this.krw, required this.nextUpdate});

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      krw: (json['conversion_rates']['KRW'] as num).toDouble(),
      nextUpdate: DateTime.fromMillisecondsSinceEpoch(
        json['time_next_update_unix'] * 1000,
      ).toLocal(),
    );
  }
}
