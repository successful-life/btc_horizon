/// UTC 월요일 00:00부터 다음 월요일 전까지의 주봉입니다.
class TrendCandle {
  final DateTime openTime;
  final DateTime endExclusive;
  final double open, high, low, close;

  /// 해당 주의 누적 BTC 거래량. null과 실제 0을 구분합니다.
  final double? volume;
  final bool isClosed;
  const TrendCandle({
    required this.openTime,
    required this.endExclusive,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.isClosed,
    this.volume,
  });
  DateTime get lastIncludedDate =>
      endExclusive.subtract(const Duration(days: 1));
}

class TrendOscillators {
  final List<double?> rsi, macd, signal, histogram;
  TrendOscillators({
    required List<double?> rsi,
    required List<double?> macd,
    required List<double?> signal,
    required List<double?> histogram,
  }) : rsi = List.unmodifiable(rsi),
       macd = List.unmodifiable(macd),
       signal = List.unmodifiable(signal),
       histogram = List.unmodifiable(histogram);
}

class TrendCandleSeries {
  final List<TrendCandle> candles;
  final TrendOscillators oscillators;
  TrendCandleSeries({
    required List<TrendCandle> candles,
    required this.oscillators,
  }) : candles = List.unmodifiable(candles);
}
