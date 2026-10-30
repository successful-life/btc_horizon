import 'package:btc_horizon/models/mvrv_history_cache.dart';

/// 차트 자료와 이번 서버 확인의 진행 상태를 함께 전달합니다.
class MvrvHistoryView {
  final MvrvHistoryCache snapshot;
  final bool isChecking;
  final bool verificationFailed;
  final bool persistenceFailed;

  const MvrvHistoryView({
    required this.snapshot,
    this.isChecking = false,
    this.verificationFailed = false,
    this.persistenceFailed = false,
  });
}
