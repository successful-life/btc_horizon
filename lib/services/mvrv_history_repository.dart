import 'package:btc_horizon/models/mvrv_history_cache.dart';
import 'package:btc_horizon/models/mvrv_history_view.dart';
import 'package:btc_horizon/services/firestore_mvrv_service.dart';
import 'package:btc_horizon/services/mvrv_history_cache_store.dart';

/// 기기 저장본을 먼저 전달하고, 서버 결과로 갱신합니다.
class MvrvHistoryRepository {
  MvrvHistoryRepository({
    required FirestoreMvrvService service,
    required Future<MvrvHistoryCacheStore?> store,
  }) : _service = service,
       _store = store;

  final FirestoreMvrvService _service;
  final Future<MvrvHistoryCacheStore?> _store;
  MvrvHistoryCache? _lastGood;
  bool _persistenceFailed = false;

  Stream<MvrvHistoryView> load({required bool Function() isActive}) async* {
    final store = await _store;
    if (!isActive()) return;

    // 재조회할 때는 파일보다 이번 실행에서 확인한 자료를 우선합니다.
    var previous = _lastGood;
    if (previous == null && store != null) {
      previous = await store.load();
      if (!isActive()) return;
      _lastGood = previous;
    }

    if (previous != null) {
      _service.seedHistoryCache(previous);
      yield MvrvHistoryView(
        snapshot: previous,
        isChecking: true,
        persistenceFailed: _persistenceFailed,
      );
    }
    if (!isActive()) return;

    final MvrvHistoryCache fresh;
    try {
      fresh = await _service.fetchMvrvHistorySnapshot();
    } catch (error, stackTrace) {
      // 예상 가능한 통신·데이터 오류만 이전 차트로 처리합니다.
      // 프로그래밍 오류까지 정상 캐시 동작으로 숨기지 않습니다.
      if (error is! Exception && error is! StateError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      if (!isActive()) return;
      if (previous == null) rethrow;
      yield MvrvHistoryView(
        snapshot: previous,
        verificationFailed: true,
        persistenceFailed: _persistenceFailed,
      );
      return;
    }
    if (!isActive()) return;

    _lastGood = fresh;
    var saveFailed = store == null;
    if (store != null) {
      try {
        await store.save(fresh);
      } on Exception {
        saveFailed = true;
      }
    }
    if (!isActive()) return;

    _persistenceFailed = saveFailed;
    yield MvrvHistoryView(snapshot: fresh, persistenceFailed: saveFailed);
  }
}
