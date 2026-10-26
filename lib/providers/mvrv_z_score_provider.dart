import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/providers/mvrv_history_provider.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mvrvZScoreProvider = FutureProvider<MvrvHistoryPointModel>((ref) {
  final service = ref.watch(firestoreMvrvServiceProvider);

  return fetchWithRefresh(
    ref: ref,
    fetch: service.fetchLatestConfirmed,
    refreshAfter: kMvrvRefreshInterval,
    retryAfter: kMvrvRetryInterval,
  );
}, retry: disableAutomaticRetry);
