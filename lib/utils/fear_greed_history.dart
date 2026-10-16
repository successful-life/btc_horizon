import 'package:btc_horizon/models/fear_greed_model.dart';

/// 차트 표시 전용. 시작일과 종료일의 기록을 모두 포함합니다.
class FearGreedWindow {
  const FearGreedWindow(this.start, this.end);
  final DateTime start;
  final DateTime end;

  factory FearGreedWindow.fromFractions(DateTime first, DateTime last, double start, double end) {
    first = fearGreedDay(first);
    last = fearGreedDay(last);
    final days = last.difference(first).inDays;
    if (days <= 0) return FearGreedWindow(first, first);
    final minimum = days < 7 ? days : 7;
    var a = (start.clamp(0.0, 1.0) * days).round();
    var b = (end.clamp(0.0, 1.0) * days).round();
    if (b - a < minimum) b = a + minimum;
    if (b > days) {
      b = days;
      a = b - minimum;
    }
    return FearGreedWindow(first.add(Duration(days: a)), first.add(Duration(days: b)));
  }

  FearGreedWindow clamp(DateTime first, DateTime last) {
    first = fearGreedDay(first);
    last = fearGreedDay(last);
    final days = last.difference(first).inDays;
    if (days <= 0) return FearGreedWindow(first, first);
    return FearGreedWindow.fromFractions(
      first,
      last,
      fearGreedDay(start).difference(first).inDays / days,
      fearGreedDay(end).difference(first).inDays / days,
    );
  }

  List<FearGreedModel> select(List<FearGreedModel> values) => values.where((value) {
    final day = fearGreedDay(value.timestamp);
    return !day.isBefore(start) && !day.isAfter(end);
  }).toList();
}

enum FearGreedPeriod {
  quarter('3개월'),
  year('1년'),
  all('전체');

  const FearGreedPeriod(this.label);
  final String label;
}

/// 날짜 비교는 제공처의 UTC 날짜로 통일합니다.
DateTime fearGreedDay(DateTime date) {
  final utc = date.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

List<FearGreedModel> normalizeFearGreedHistory(
  Iterable<FearGreedModel> values, {
  FearGreedModel? latest,
}) {
  final days = <DateTime, FearGreedModel>{};
  for (final value in values) {
    if (!value.value.isFinite || value.value < 0 || value.value > 100) continue;
    final day = fearGreedDay(value.timestamp);
    final previous = days[day];
    if (previous == null || value.timestamp.isAfter(previous.timestamp)) {
      days[day] = value;
    }
  }
  // 최신 점수 provider의 새 기록을 같은 날짜의 과거 응답보다 우선합니다.
  if (latest != null && latest.value.isFinite && latest.value >= 0 && latest.value <= 100) {
    days[fearGreedDay(latest.timestamp)] = latest;
  }
  final result = days.values.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return List.unmodifiable(result);
}

DateTime fearGreedPeriodStart(DateTime end, FearGreedPeriod period) {
  final day = fearGreedDay(end);
  if (period == FearGreedPeriod.all) return DateTime.utc(1970);
  final months = period == FearGreedPeriod.year ? 12 : 3;
  final first = DateTime.utc(day.year, day.month - months);
  final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
  return DateTime.utc(first.year, first.month, day.day > lastDay ? lastDay : day.day);
}

List<FearGreedModel> fearGreedVisibleHistory(List<FearGreedModel> values, FearGreedPeriod period) {
  if (values.isEmpty || period == FearGreedPeriod.all) return values;
  final start = fearGreedPeriodStart(values.last.timestamp, period);
  return values.where((v) => !fearGreedDay(v.timestamp).isBefore(start)).toList();
}

double? fearGreedDayChange(List<FearGreedModel> values) {
  if (values.length < 2) return null;
  final latest = values.last;
  final yesterday = fearGreedDay(latest.timestamp).subtract(const Duration(days: 1));
  for (final value in values.reversed.skip(1)) {
    if (fearGreedDay(value.timestamp) == yesterday) {
      return latest.value - value.value;
    }
  }
  return null;
}

/// 누락된 날을 무시하고 '최근 7개'를 평균내지 않습니다.
double? fearGreedWeekAverage(List<FearGreedModel> values) {
  if (values.isEmpty) return null;
  final start = fearGreedDay(values.last.timestamp).subtract(const Duration(days: 6));
  final week = values.where((v) => !fearGreedDay(v.timestamp).isBefore(start)).toList();
  if (week.length != 7) return null;
  return week.fold<double>(0, (sum, v) => sum + v.value) / 7;
}

/// 기존 앱의 상태 구간과 동일합니다. 점수 계산에는 사용하지 않습니다.
String fearGreedLabel(double value) => switch (value) {
  >= 75 => '극단적 탐욕',
  >= 55 => '탐욕',
  >= 45 => '중립',
  >= 25 => '공포',
  _ => '극단적 공포',
};
