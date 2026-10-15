import 'package:btc_horizon/models/weekly_trend_market_model.dart';
import 'package:btc_horizon/providers/binance_kline_provider.dart';
import 'package:btc_horizon/services/binance_weekly_trend_service.dart';
import 'package:btc_horizon/utils/trend_candle_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final binanceWeeklyTrendServiceProvider = Provider.autoDispose<BinanceWeeklyTrendService>((ref) {
  final rest = ref.watch(binanceKlineServiceProvider);
  final service = BinanceWeeklyTrendService(
    fetchHistory: () => rest.fetchKlines(symbol: 'BTCUSDT', interval: '1w', limit: 1000),
  );
  ref.onDispose(service.dispose);
  return service;
});

final weeklyMarketSnapshotProvider = StreamProvider.autoDispose<WeeklyMarketSnapshot>((ref) {
  return ref.watch(binanceWeeklyTrendServiceProvider).stream;
}, retry: (_, _) => null); // 서비스에서 재연결을 관리합니다.

// 홈·상세·확대 화면이 같은 스냅샷을 공유합니다.
final trendMarketProvider = Provider.autoDispose<AsyncValue<WeeklyTrendMarket>>((ref) {
  return ref.watch(weeklyMarketSnapshotProvider).whenData(buildWeeklyTrendMarket);
});
