import 'dart:async';

/// 일회성 refresh를 등록함
/// 백그라운드에서 경과한 시간은 앱이 resume될 때 한 번 반영함
class RefreshScheduler {
  RefreshScheduler({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<Object, _RefreshJob> _jobs = {};
  Timer? _timer;
  bool _active = false;
  bool _disposed = false;

  void Function() schedule(DateTime dueAt, void Function() callback) {
    if (_disposed) throw StateError('RefreshScheduler is disposed.');
    final key = Object();
    _jobs[key] = _RefreshJob(dueAt, callback);
    _armTimer();
    return () {
      _jobs.remove(key);
      _armTimer();
    };
  }

  void setActive(bool active) {
    if (_disposed) return;
    _active = active;
    _armTimer();
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || !_active || _jobs.isEmpty) return;
    final next = _jobs.values.map((job) => job.dueAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final delay = next.difference(_now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, _runDueJobs);
  }

  void _runDueJobs() {
    if (_disposed || !_active) return;
    final now = _now();
    final keys = _jobs.entries
        .where((entry) => !entry.value.dueAt.isAfter(now))
        .map((entry) => entry.key)
        .toList();
    try {
      for (final key in keys) {
        if (_disposed || !_active) break;
        final job = _jobs.remove(key);
        job?.callback();
      }
    } finally {
      _armTimer();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _jobs.clear();
  }
}

class _RefreshJob {
  const _RefreshJob(this.dueAt, this.callback);
  final DateTime dueAt;
  final void Function() callback;
}
