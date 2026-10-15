import 'package:btc_horizon/models/trend_candle_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';

enum TrendConnection { connecting, live, reconnecting }

class WeeklyMarketSnapshot {
  final List<TrendCandle> candles;
  final TrendConnection connection;
  final DateTime receivedAt;
  final DateTime? eventTime;
  WeeklyMarketSnapshot({
    required List<TrendCandle> candles,
    required this.connection,
    required this.receivedAt,
    this.eventTime,
  }) : candles = List.unmodifiable(candles);
  bool get isLive => connection == TrendConnection.live;
}

class WeeklyTrendMarket {
  final WeeklyMarketSnapshot snapshot;
  final TrendCandleSeries series;
  final TrendChartDataModel lines;
  const WeeklyTrendMarket({
    required this.snapshot,
    required this.series,
    required this.lines,
  });
}
