import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

/// 표시 기간에 따라 연·월·일 눈금을 선택하는 공용 날짜 축입니다.
class ChartDateAxis extends StatelessWidget {
  final DateTime firstDate;
  final int startDay;
  final int endDay;
  const ChartDateAxis({
    super.key,
    required this.firstDate,
    required this.startDay,
    required this.endDay,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final style = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 10, color: const Color(0xFF667085), height: 1.2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= 0 || endDay <= startDay) {
          return const SizedBox.shrink();
        }
        Size measure(String text) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: ui.TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: width);
          final size = Size(math.min(width, painter.width.ceilToDouble() + 2), painter.height);
          painter.dispose();
          return size;
        }

        final ticks = _calendarTicks(
          firstDate: firstDate,
          startDay: startDay,
          endDay: endDay,
          width: width,
          measure: measure,
        );
        final height = ticks.fold<double>(0, (height, tick) => math.max(height, tick.size.height));
        return SizedBox(
          height: height + 16,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF3)),
              ),
              for (final tick in ticks) ...[
                Positioned(
                  left: tick.x.clamp(0.0, math.max(0.0, width - 1)),
                  top: 0,
                  child: const SizedBox(
                    width: 1,
                    height: 4,
                    child: ColoredBox(color: Color(0xFFE8EDF3)),
                  ),
                ),
                Positioned(
                  left: tick.left,
                  top: 8,
                  width: tick.size.width,
                  child: Text(
                    tick.text,
                    style: style,
                    textScaler: scaler,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CalendarTick {
  final double x;
  final double left;
  final String text;
  final Size size;
  const _CalendarTick(this.x, this.left, this.text, this.size);
}

// 연도/월/일의 달력 경계에 맞춰 눈금을 만듭니다.
// 글자를 실제로 측정해서 겹치지 않는 가장 촘촘한 간격을 선택합니다.
List<_CalendarTick> _calendarTicks({
  required DateTime firstDate,
  required int startDay,
  required int endDay,
  required double width,
  required Size Function(String) measure,
}) {
  final base = chartCalendarDayKey(firstDate);
  final first = base + startDay;
  final last = base + endDay;
  DateTime dateFor(int day) =>
      DateTime.fromMillisecondsSinceEpoch(day * Duration.millisecondsPerDay, isUtc: true);
  final start = dateFor(first);
  final span = endDay - startDay;
  final unit = span >= 730
      ? 'year'
      : span > 90
      ? 'month'
      : 'day';
  final steps = switch (unit) {
    'year' => [1, 2, 4, 5, 10, 20, 50, 100],
    'month' => [1, 2, 3, 6, 12, 24],
    _ => [1, 2, 7, 14, 28, 56, 112],
  };
  final format = DateFormat(
    unit == 'year'
        ? 'yyyy'
        : unit == 'month'
        ? 'yy.MM'
        : 'MM/dd',
  );
  for (final step in steps) {
    final days = <int>[];
    if (unit == 'year') {
      var year = (start.year / step).ceil() * step;
      while (chartCalendarDayKey(DateTime.utc(year)) < first) {
        year += step;
      }
      for (; chartCalendarDayKey(DateTime.utc(year)) <= last; year += step) {
        days.add(chartCalendarDayKey(DateTime.utc(year)));
      }
    } else if (unit == 'month') {
      var month = ((start.year * 12 + start.month - 1) / step).ceil() * step;
      int key(int value) => chartCalendarDayKey(DateTime.utc(value ~/ 12, value % 12 + 1));
      while (key(month) < first) {
        month += step;
      }
      for (; key(month) <= last; month += step) {
        days.add(key(month));
      }
    } else {
      // 7일 이상 간격은 월요일을 기준으로 정렬합니다.
      final anchor = step >= 7 ? 4 : 0; // 1970/01/05
      final begin = ((first - anchor) / step).ceil() * step + anchor;
      for (var day = begin; day <= last; day += step) {
        days.add(day);
      }
    }
    final ticks = <_CalendarTick>[];
    var previousRight = double.negativeInfinity;
    var fits = true;
    for (final day in days) {
      final text = format.format(dateFor(day));
      final size = measure(text);
      final x = (day - first) / span * width;
      final left = (x - size.width / 2).clamp(0.0, math.max(0.0, width - size.width)).toDouble();
      if (left < previousRight + 8) {
        fits = false;
        break;
      }
      ticks.add(_CalendarTick(x, left, text, size));
      previousRight = left + size.width;
    }
    if (fits && ticks.isNotEmpty) {
      return ticks;
    }
  }
  // 아주 작은 화면에서도 읽을 수 있는 날짜 하나는 남깁니다.
  final day = first + span ~/ 2;
  final text = format.format(dateFor(day));
  final size = measure(text);
  return [_CalendarTick(width / 2, (width - size.width) / 2, text, size)];
}

// 시간대를 변환하지 않고 날짜의 연·월·일을 기준으로 비교합니다.
int chartCalendarDayKey(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
