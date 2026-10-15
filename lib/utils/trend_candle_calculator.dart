import 'dart:math' as math;
import 'package:btc_horizon/models/binance_kline_model.dart';
import 'package:btc_horizon/models/trend_candle_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:btc_horizon/models/weekly_trend_market_model.dart';
import 'package:btc_horizon/utils/trend_calculator.dart';

DateTime trendWeekEnd(DateTime openTime) => openTime.toUtc().add(const Duration(days: 7));

void validateTrendCandle(TrendCandle c) {
  final t = c.openTime.toUtc();
  if (t.weekday != DateTime.monday ||
      t.hour != 0 ||
      t.minute != 0 ||
      t.second != 0 ||
      t.millisecond != 0 ||
      t.microsecond != 0 ||
      c.endExclusive != trendWeekEnd(t) ||
      [c.open, c.high, c.low, c.close].any((v) => !v.isFinite || v <= 0) ||
      (c.volume != null && (!c.volume!.isFinite || c.volume! < 0)) ||
      c.high < math.max(c.open, c.close) ||
      c.low > math.min(c.open, c.close)) {
    throw const FormatException('유효하지 않은 UTC 주봉입니다.');
  }
}

List<TrendCandle> weeklyCandlesFromRest(List<BinanceKlineModel> klines, DateTime now) {
  final sorted = [...klines]..sort((a, b) => a.openTime.compareTo(b.openTime));
  final result = <TrendCandle>[];
  for (final k in sorted) {
    final open = k.openTime.toUtc();
    if (open.isAfter(now.toUtc())) {
      throw const FormatException('미래 주봉 시작 시각입니다.');
    }
    final c = TrendCandle(
      openTime: open,
      endExclusive: trendWeekEnd(open),
      open: k.open,
      high: k.high,
      low: k.low,
      close: k.close,
      volume: k.volume,
      isClosed: !trendWeekEnd(open).isAfter(now.toUtc()),
    );
    validateTrendCandle(c);
    if (result.isNotEmpty && result.last.endExclusive != open) {
      throw const FormatException('주봉 날짜가 중복되거나 누락되었습니다.');
    }
    result.add(c);
  }
  if (result.isEmpty) {
    throw StateError('주봉 데이터가 비어 있습니다.');
  }
  return result;
}

/// Wilder 방식: 최초 14개 변화량을 평균내고 이후 1/14로 평활합니다.
/// 변동이 전혀 없는 구간은 이 앱에서 중립값 50으로 처리합니다.
List<double?> calculateTrendRsi(List<double> closes, {int period = 14}) {
  if (period < 1) {
    throw ArgumentError.value(period, 'period');
  }
  final output = List<double?>.filled(closes.length, null);
  if (closes.length <= period) {
    return output;
  }
  var gain = 0.0, loss = 0.0;
  for (var i = 1; i <= period; i++) {
    final change = closes[i] - closes[i - 1];
    gain += math.max(change, 0);
    loss += math.max(-change, 0);
  }
  gain /= period;
  loss /= period;
  double value() => gain == 0 && loss == 0
      ? 50
      : loss == 0
      ? 100
      : 100 - 100 / (1 + gain / loss);
  output[period] = value();
  for (var i = period + 1; i < closes.length; i++) {
    final change = closes[i] - closes[i - 1];
    gain = (gain * (period - 1) + math.max(change, 0)) / period;
    loss = (loss * (period - 1) + math.max(-change, 0)) / period;
    output[i] = value();
  }
  return output;
}

/// 첫 period개 값의 SMA를 seed로 사용합니다. 준비 구간은 null입니다.
List<double?> trendEmaValues(List<double> values, int period) {
  if (period < 1) {
    throw ArgumentError.value(period, 'period');
  }
  final output = List<double?>.filled(values.length, null);
  if (values.length < period) {
    return output;
  }
  var previous = values.take(period).reduce((a, b) => a + b) / period;
  output[period - 1] = previous;
  final alpha = 2 / (period + 1);
  for (var i = period; i < values.length; i++) {
    previous += alpha * (values[i] - previous);
    output[i] = previous;
  }
  return output;
}

TrendOscillators calculateTrendOscillators(List<double> closes) {
  final fast = trendEmaValues(closes, 12);
  final slow = trendEmaValues(closes, 26);
  final macd = List<double?>.filled(closes.length, null);
  final signal = List<double?>.filled(closes.length, null);
  final histogram = List<double?>.filled(closes.length, null);
  for (var i = 25; i < closes.length; i++) {
    macd[i] = fast[i]! - slow[i]!;
  }
  final signalTail = trendEmaValues(macd.whereType<double>().toList(), 9);
  for (var i = 0; i < signalTail.length; i++) {
    signal[i + 25] = signalTail[i];
    if (signalTail[i] != null) {
      histogram[i + 25] = macd[i + 25]! - signalTail[i]!;
    }
  }
  return TrendOscillators(
    rsi: calculateTrendRsi(closes),
    macd: macd,
    signal: signal,
    histogram: histogram,
  );
}

WeeklyTrendMarket buildWeeklyTrendMarket(WeeklyMarketSnapshot snapshot) {
  final candles = snapshot.candles;
  final series = TrendCandleSeries(
    candles: candles,
    oscillators: calculateTrendOscillators(candles.map((c) => c.close).toList()),
  );
  final klines = candles
      .map(
        (c) => BinanceKlineModel(
          openTime: c.openTime,
          open: c.open,
          high: c.high,
          low: c.low,
          close: c.close,
          volume: c.volume,
        ),
      )
      .toList();
  // 주봉끼리 비교하므로 각 계산값을 해당 주봉 위치에 표시합니다.
  // 마지막 진행 봉은 매번 교체하여 EMA/RSI에 같은 주를 중복 누적하지 않습니다.
  List<TrendChartPoint> points(List<double?> values) => [
    for (var i = 0; i < values.length; i++)
      if (values[i] != null) TrendChartPoint(time: candles[i].openTime, value: values[i]!),
  ];
  final lines = TrendChartDataModel(
    price: [for (final c in candles) TrendChartPoint(time: c.openTime, value: c.close)],
    trendBaseline: points(calculateSma(klines: klines, period: 52)),
    upperTrendThreshold: points(calculateEma(klines: klines, period: 10)),
    lowerTrendThreshold: points(calculateSsma(klines: klines, period: 111)),
    bottomRangeBoundary: points(calculateSsma(klines: klines, period: 200)),
  );
  return WeeklyTrendMarket(snapshot: snapshot, series: series, lines: lines);
}

double? trendValueAt(List<TrendChartPoint> points, DateTime time) {
  var low = 0, high = points.length;
  while (low < high) {
    final mid = (low + high) ~/ 2;
    if (!points[mid].time.isAfter(time)) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low == 0 ? null : points[low - 1].value;
}
