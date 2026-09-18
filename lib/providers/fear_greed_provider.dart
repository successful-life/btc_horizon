import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/fear_greed_model.dart';
import 'package:btc_horizon/services/fear_greed_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fearGreedServiceProvider = Provider<FearGreedService>((ref) {
  return FearGreedService();
});

final fearGreedProvider = FutureProvider<FearGreedModel>((ref) {
  final service = ref.read(fearGreedServiceProvider);
  return fetchWithRefresh(
    ref: ref,
    fetch: () async {
      final values = await service.fetchFearGreed(limit: 1);
      if (values.isEmpty) throw StateError('Fear & Greed 데이터가 비어 있습니다.');
      return values.first;
    },
    refreshAfter: kMetadataFallbackInterval,
    nextRefreshAt: (data, fetchedAt) {
      final seconds = data.timeUntilUpdate;
      return seconds != null && seconds > 0
          ? fetchedAt
                .add(Duration(seconds: seconds))
                .add(const Duration(minutes: 2))
          : fetchedAt.add(kMetadataFallbackInterval);
    },
  );
}, retry: disableAutomaticRetry);
