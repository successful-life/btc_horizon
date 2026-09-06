import 'package:btc_horizon/models/halving_cycle_model.dart';

// 현재 사이클 진행률 계산
double calculateCycleProgress({required HalvingCycleModel cycle, required DateTime today}) {
  final elapsed = today.difference(cycle.startDate).inSeconds;

  final total = cycle.endDate.difference(cycle.startDate).inSeconds;

  return elapsed / total;
}

// 현재 사이클 진행률을 과거 사이클에 적용해서 계산
List<DateTime> calculateEquivalentDates({
  required List<HalvingCycleModel> cycles,
  required double progress,
}) {
  return cycles.map((cycle) => _calculateEquivalentDate(cycle: cycle, progress: progress)).toList();
}

DateTime _calculateEquivalentDate({required HalvingCycleModel cycle, required double progress}) {
  final cycleDuration = cycle.endDate.difference(cycle.startDate);

  final elapsedSeconds = (cycleDuration.inSeconds * progress).round();

  return cycle.startDate.add(Duration(seconds: elapsedSeconds));
}
