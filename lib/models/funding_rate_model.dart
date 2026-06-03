class FundingRateModel {
  final double fundingRate;
  final DateTime nextFundingTime;

  FundingRateModel({required this.fundingRate, required this.nextFundingTime});

  factory FundingRateModel.fromJson(Map<String, dynamic> json) {
    return FundingRateModel(
      fundingRate: double.parse(json['lastFundingRate'] as String),
      nextFundingTime: DateTime.fromMillisecondsSinceEpoch(json['nextFundingTime']).toLocal(),
    );
  }
}
