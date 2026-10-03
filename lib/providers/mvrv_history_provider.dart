import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/services/kote_mvrv_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final koteMvrvServiceProvider = Provider<KoteMvrvService>((ref) {
  return KoteMvrvService();
});

final mvrvHistoryProvider = FutureProvider<MvrvHistoryModel>((ref) {
  final service = ref.watch(koteMvrvServiceProvider);

  return fetchWithRefresh(
    ref: ref,
    fetch: service.fetchMvrvHistory,
    refreshAfter: kMvrvRefreshInterval,
    retryAfter: kMvrvRetryInterval,
  );
}, retry: disableAutomaticRetry);
