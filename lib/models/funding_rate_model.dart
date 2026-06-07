class FundingRateModel {
  final double lastFundingRate;
  final DateTime nextFundingTime;

  FundingRateModel({required this.lastFundingRate, required this.nextFundingTime});

  factory FundingRateModel.fromJson(Map<String, dynamic> json) {
    return FundingRateModel(
      lastFundingRate: double.parse(json['lastFundingRate'] as String),
      nextFundingTime: DateTime.fromMillisecondsSinceEpoch(json['nextFundingTime']).toLocal(),
    );
  }
}
