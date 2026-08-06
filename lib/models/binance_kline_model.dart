class BinanceKlineModel {
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;

  BinanceKlineModel({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory BinanceKlineModel.fromJson(List<dynamic> json) {
    return BinanceKlineModel(
      openTime: DateTime.fromMillisecondsSinceEpoch(json[0] as int),
      open: double.parse(json[1] as String),
      high: double.parse(json[2] as String),
      low: double.parse(json[3] as String),
      close: double.parse(json[4] as String),
    );
  }
}
/*
  [0]  (int)     "Open time"					-> 1499040000000
  [1]  (String)  "Open"					      -> 0.01634790
  [2]  (String)  "High"					      -> 0.80000000
  [3]  (String)  "Low"					      -> 0.01575800
  [4]  (String)  "Close"					    -> 0.01577100
  [5]  (String)  "Volume"					    -> 148976.11427815
  [6]  (int)     "Close time"					-> 1499644799999
  [7]  (String)  "Quote asset volume"			        -> 2434.19055334
  [8]  (int)     "Number of trades"				        -> 308
  [9]  (String)  "Taker buy base asset volume"	  -> 1756.87402397
  [10]  (String)  "Taker buy quote asset volume"	-> 28.46694368
  [11]  (String)  "Ignore"					              -> 0
*/