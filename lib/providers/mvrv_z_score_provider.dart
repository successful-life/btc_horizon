import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/models/mvrv_latest_model.dart';
import 'package:btc_horizon/providers/mvrv_history_provider.dart';
import 'package:btc_horizon/providers/refresh_scheduler_provider.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 최신 MVRV 값과 기준일·수집 시각·확인 시각을 제공합니다.
final mvrvLatestProvider = FutureProvider<MvrvLatestModel>((ref) {
  final service = ref.watch(firestoreMvrvServiceProvider);
  final now = ref.watch(nowProvider);

  return fetchWithRefresh(
    ref: ref,
    fetch: () async {
      final data = await service.fetchLatest(now: now);
      return data;
    },
    refreshAfter: kMvrvRefreshInterval,
    retryAfter: kMvrvRetryInterval,
  );
}, retry: disableAutomaticRetry);

/// 기존 점수 계산 코드에는 최신 확정 기록 한 건만 전달합니다.
final mvrvZScoreProvider = Provider<AsyncValue<MvrvHistoryPointModel>>((ref) {
  final latestAsync = ref.watch(mvrvLatestProvider);

  return latestAsync.whenData((data) => data.latestConfirmed);
});
