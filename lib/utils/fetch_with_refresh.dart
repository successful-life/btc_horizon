import 'package:btc_horizon/providers/refresh_scheduler_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// retry와 함께 FutureProvider 내부에서 사용함: disableAutomaticRetry.
/// 요청이 진행 중일 때는 타이머가 존재하지 않음
/// dispose되면 다음 예약 작업이 취소됨
Future<T> fetchWithRefresh<T>({
  required Ref ref,
  required Future<T> Function() fetch,
  required Duration refreshAfter,
  Duration retryAfter = const Duration(minutes: 15),
  DateTime Function(T data, DateTime fetchedAt)? nextRefreshAt,
}) async {
  final scheduler = ref.watch(refreshSchedulerProvider);
  final now = ref.watch(nowProvider);
  void Function()? cancelRefresh;
  ref.onDispose(() => cancelRefresh?.call());

  void schedule(DateTime dueAt) {
    if (!ref.mounted) return;
    // 만료된 상위 API의 타임스탬프로 인해 요청이 과도하게 반복되어서는 안 됨
    final earliest = now().add(const Duration(minutes: 1));
    cancelRefresh = scheduler.schedule(dueAt.isBefore(earliest) ? earliest : dueAt, () {
      if (ref.mounted) ref.invalidateSelf();
    });
  }

  try {
    final data = await fetch();
    if (ref.mounted) {
      final fetchedAt = now();
      schedule(nextRefreshAt?.call(data, fetchedAt) ?? fetchedAt.add(refreshAfter));
    }
    return data;
  } catch (_) {
    schedule(now().add(retryAfter));
    rethrow;
  }
}

// 예약된 재시도가 요청 타이밍을 직접 관리하도록 함
// Rate Limit이 적용되는 엔드포인트도 포함한다.
Duration? disableAutomaticRetry(int retryCount, Object error) => null;
