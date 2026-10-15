class BinanceKlineModel {
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;

  /// Base asset 거래량. BTCUSDT에서는 BTC 단위이며 null은 데이터 없음입니다.
  final double? volume;

  const BinanceKlineModel({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  factory BinanceKlineModel.fromJson(List<dynamic> json) {
    final volume = double.tryParse(json[5].toString());
    if (volume == null || !volume.isFinite || volume < 0) {
      throw const FormatException('유효하지 않은 거래량입니다.');
    }
    return BinanceKlineModel(
      openTime: DateTime.fromMillisecondsSinceEpoch(json[0] as int),
      open: double.parse(json[1] as String),
      high: double.parse(json[2] as String),
      low: double.parse(json[3] as String),
      close: double.parse(json[4] as String),
      volume: volume,
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
