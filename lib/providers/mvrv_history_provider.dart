import 'package:btc_horizon/services/mvrv_history_repository.dart';
import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/mvrv_history_view.dart';
import 'package:btc_horizon/providers/mvrv_history_cache_store_provider.dart';
import 'package:btc_horizon/providers/refresh_scheduler_provider.dart';
import 'package:btc_horizon/services/firestore_mvrv_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final firestoreMvrvServiceProvider = Provider<FirestoreMvrvService>((ref) {
  final db = FirebaseFirestore.instance;
  final now = ref.watch(nowProvider);

  return FirestoreMvrvService(
    now: now,
    loadDocument: (path) async {
      if (kDebugMode) debugPrint('MVRV Firestore 조회 요청: $path');
      final snapshot = await db
          .doc(path)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      final collectedAt = data['collectedAt'];

      return <String, dynamic>{
        ...data,
        if (collectedAt is Timestamp) 'collectedAt': collectedAt.toDate().toUtc(),
      };
    },
  );
});

final mvrvHistoryRepositoryProvider = Provider<MvrvHistoryRepository>((ref) {
  return MvrvHistoryRepository(
    service: ref.watch(firestoreMvrvServiceProvider),
    store: ref.watch(mvrvHistoryCacheStoreProvider.future),
  );
});

final mvrvHistoryProvider = StreamProvider<MvrvHistoryView>((ref) async* {
  final repository = ref.watch(mvrvHistoryRepositoryProvider);
  final scheduler = ref.watch(refreshSchedulerProvider);
  final now = ref.watch(nowProvider);
  void Function()? cancelRefresh;

  ref.onDispose(() => cancelRefresh?.call());

  void schedule(Duration delay) {
    if (!ref.mounted) return;
    cancelRefresh?.call();
    cancelRefresh = scheduler.schedule(now().add(delay), () {
      if (ref.mounted) ref.invalidateSelf();
    });
  }

  try {
    await for (final view in repository.load(isActive: () => ref.mounted)) {
      if (!ref.mounted) return;
      if (!view.isChecking) {
        schedule(view.verificationFailed ? kMvrvRetryInterval : kMvrvRefreshInterval);
      }
      yield view;
    }
  } catch (_) {
    schedule(kMvrvRetryInterval);
    rethrow;
  }
}, retry: disableAutomaticRetry);
