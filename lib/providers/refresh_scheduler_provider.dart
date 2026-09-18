import 'package:btc_horizon/services/refresh_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 테스트에서는 기기의 시간을 변경하지 않고 clock을 주입함
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final refreshSchedulerProvider = Provider<RefreshScheduler>((ref) {
  final scheduler = RefreshScheduler(now: ref.watch(nowProvider));
  ref.onDispose(scheduler.dispose);
  return scheduler;
});
