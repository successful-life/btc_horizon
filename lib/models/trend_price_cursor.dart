import 'package:btc_horizon/models/trend_candle_model.dart';

enum TrendSnapPoint {
  open('시가'),
  high('고가'),
  low('저가'),
  close('종가');

  const TrendSnapPoint(this.label);
  final String label;
  double value(TrendCandle candle) => switch (this) {
    open => candle.open,
    high => candle.high,
    low => candle.low,
    close => candle.close,
  };
}

/// index는 봉 중심을 정수로 하는 가로 위치이며 자유 선택에서는 소수도 유지합니다.
class TrendPriceCursor {
  final double index, price;
  final TrendSnapPoint? snapPoint;
  const TrendPriceCursor({required this.index, required this.price, this.snapPoint});
}
