import 'package:btc_horizon/providers/refresh_scheduler_provider.dart';
import 'package:btc_horizon/services/refresh_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analysisDateProvider = NotifierProvider<AnalysisDateNotifier, DateTime>(
  AnalysisDateNotifier.new,
);

class AnalysisDateNotifier extends Notifier<DateTime> {
  late RefreshScheduler _scheduler;
  late DateTime Function() _now;
  void Function()? _cancelRefresh;

  @override
  DateTime build() {
    _scheduler = ref.watch(refreshSchedulerProvider);
    _now = ref.watch(nowProvider);
    ref.onDispose(() => _cancelRefresh?.call());
    final now = _now();
    _scheduleNextMidnight(now);
    return DateTime(now.year, now.month, now.day);
  }

  void refresh() {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    if (state != today) state = today;
    _scheduleNextMidnight(now);
  }

  void _scheduleNextMidnight(DateTime now) {
    _cancelRefresh?.call();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _cancelRefresh = _scheduler.schedule(midnight, refresh);
  }
}
