class CoinPriceModel {
  final String symbol;
  final double price;

  CoinPriceModel({required this.symbol, required this.price});

  factory CoinPriceModel.fromJson(Map<String, dynamic> json) {
    return CoinPriceModel(symbol: json['symbol'], price: double.parse(json['price']));
  }
}
