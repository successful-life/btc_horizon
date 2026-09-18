import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/binance_kline_model.dart';
import 'package:btc_horizon/models/binance_kline_request_model.dart';
import 'package:btc_horizon/services/binance_kline_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final binanceKlineServiceProvider = Provider<BinanceKlineService>((ref) {
  return BinanceKlineService();
});

final binanceKlineProvider =
    FutureProvider.family<List<BinanceKlineModel>, BinanceKlineRequestModel>((ref, request) {
      final service = ref.read(binanceKlineServiceProvider);
      return fetchWithRefresh(
        ref: ref,
        fetch: () => service.fetchKlines(
          symbol: request.symbol.restApi,
          interval: request.interval.value,
          limit: request.limit,
        ),
        refreshAfter: kKlineRefreshInterval,
      );
    }, retry: disableAutomaticRetry);
