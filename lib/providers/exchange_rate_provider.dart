import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/exchange_rate_model.dart';
import 'package:btc_horizon/services/exchange_rate_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

final exchangeRateProvider = FutureProvider<ExchangeRateModel>((ref) {
  final service = ref.read(exchangeRateServiceProvider);
  return fetchWithRefresh(
    ref: ref,
    fetch: service.fetchExchangeRate,
    refreshAfter: kMetadataFallbackInterval,
    nextRefreshAt: (data, fetchedAt) => data.nextUpdate.isAfter(fetchedAt)
        ? data.nextUpdate.add(const Duration(minutes: 5))
        : fetchedAt.add(kMetadataFallbackInterval),
  );
}, retry: disableAutomaticRetry);
