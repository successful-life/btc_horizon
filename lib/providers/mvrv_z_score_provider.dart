import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/mvrv_z_score_model.dart';
import 'package:btc_horizon/services/mvrv_z_score_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mvrvZScoreServiceProvider = Provider<MvrvZScoreService>((ref) {
  return MvrvZScoreService();
});

final mvrvZScoreProvider = FutureProvider<MvrvZScoreModel>((ref) {
  final service = ref.read(mvrvZScoreServiceProvider);
  return fetchWithRefresh(
    ref: ref,
    fetch: service.fetchMvrvZScore,
    refreshAfter: kMvrvRefreshInterval,
    retryAfter: kMvrvRetryInterval,
  );
}, retry: disableAutomaticRetry);
