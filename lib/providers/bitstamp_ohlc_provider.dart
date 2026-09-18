import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/enums/bitstamp_symbol.dart';
import 'package:btc_horizon/models/bitstamp_ohlc_model.dart';
import 'package:btc_horizon/services/bitstamp_ohlc_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bitstampOhlcServiceProvider = Provider<BitstampOhlcService>((ref) {
  return BitstampOhlcService();
});

final bitstampOhlcProvider =
    FutureProvider.family<List<BitstampOhlcModel>, BitstampSymbol>((
      ref,
      symbol,
    ) {
      final service = ref.read(bitstampOhlcServiceProvider);
      return fetchWithRefresh(
        ref: ref,
        fetch: () => service.fetchAllOhlc(
          symbol: symbol,
          step: 86400,
          startTime: DateTime(2011, 8, 18),
        ),
        refreshAfter: const Duration(days: 1),
        nextRefreshAt: (_, fetchedAt) => nextUtcDailyRefresh(fetchedAt),
      );
    }, retry: disableAutomaticRetry);
