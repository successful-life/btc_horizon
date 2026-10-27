import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/services/firestore_mvrv_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreMvrvServiceProvider = Provider<FirestoreMvrvService>((ref) {
  final db = FirebaseFirestore.instance;

  return FirestoreMvrvService(
    loadDocument: (path) async {
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

final mvrvHistoryProvider = FutureProvider<MvrvHistoryModel>((ref) {
  final service = ref.watch(firestoreMvrvServiceProvider);
  return fetchWithRefresh(
    ref: ref,
    fetch: service.fetchMvrvHistory,
    refreshAfter: kMvrvRefreshInterval,
    retryAfter: kMvrvRetryInterval,
  );
}, retry: disableAutomaticRetry);
