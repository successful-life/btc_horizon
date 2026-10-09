import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';
import 'package:btc_horizon/models/cycle_timing_estimate_model.dart';
import 'package:btc_horizon/models/cycle_timing_interval_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

/// 가격 차트와 같은 시간 축으로 화살표와 날짜 눈금을 배치합니다.
/// 화살표는 실제 기간의 길이, 라벨은 읽을 수 있는 글자 크기를 유지합니다.
class CycleTimingIntervalStrip extends StatelessWidget {
  final DateTime firstDate;
  final int startDay;
  final int endDay;
  final List<CycleTimingIntervalModel> firstIntervals;
  final List<CycleTimingIntervalModel> secondIntervals;
  final String firstLabel;
  final String secondLabel;
  final Color firstColor;
  final Color secondColor;
  final bool compact;
  // 실제 가격이 있는 기준일만 가격 차트와 연결합니다. 기준은 firstDate입니다.
  final Set<int>? guideDays;
  // 2개의 과거 비교 행과 별도로, 다음 예상 구간을 1개 표시합니다.
  final CycleTimingEstimateModel? estimate;
  final Color estimateColor;
  final bool compareSameType;

  const CycleTimingIntervalStrip({
    super.key,
    required this.firstDate,
    required this.startDay,
    required this.endDay,
    required this.firstIntervals,
    required this.secondIntervals,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstColor,
    required this.secondColor,
    this.compact = false,
    this.guideDays,
    this.estimate,
    this.estimateColor = const Color(0xFF7C5CC4),
    this.compareSameType = false,
  });

  int _day(DateTime date) => calendarDayKey(date) - calendarDayKey(firstDate);

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final style = DefaultTextStyle.of(context).style.copyWith(
      fontSize: compact ? 9.5 : 11,
      height: 1.2,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF667085),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= 0 || endDay <= startDay) {
          return const SizedBox.shrink();
        }
        double xFor(int day) => (day - startDay) / (endDay - startDay) * width;
        Size measure(String label) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: ui.TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: math.max(1, width - 4));
          final size = painter.size;
          painter.dispose();
          return size;
        }

        _IntervalLane layoutLane(
          List<CycleTimingIntervalModel> intervals,
          String name,
          Color color,
          double top, {
          CycleTimingEstimateModel? forecast,
        }) {
          final labels = <_DurationLabel>[];
          final occupiedRows = <List<Rect>>[];
          var rowHeight = 0.0;
          final sorted = [...intervals]..sort((a, b) => a.startDate.compareTo(b.startDate));
          for (final interval in sorted) {
            final rawStart = xFor(_day(interval.startDate));
            final rawEnd = xFor(_day(interval.endDate));
            if (rawEnd <= 0 || rawStart >= width || rawEnd <= rawStart) {
              continue;
            }
            final left = rawStart.clamp(0.0, width).toDouble();
            final right = rawEnd.clamp(0.0, width).toDouble();
            final clippedLeft = rawStart < 0;
            final clippedRight = rawEnd > width;
            final forecastDays = forecast?.durationRangeDaysFor(sameType: compareSameType);
            final label = forecastDays != null
                ? '${clippedLeft || clippedRight ? '전체 ' : ''}예상 ${forecastDays.startDays}~${forecastDays.endDays}일'
                : clippedLeft || clippedRight
                ? '전체 ${interval.durationDays}일'
                : '${interval.durationDays}일';
            final size = measure(label);
            rowHeight = math.max(rowHeight, size.height + 5);
            // 화살표가 짧아도 글자는 생략하지 않습니다.
            final labelStart = forecast == null
                ? left
                : xFor(_day(forecast.rangeStartDate)).clamp(left, right).toDouble();
            final textLeft = ((labelStart + right - size.width) / 2)
                .clamp(0.0, math.max(0.0, width - size.width))
                .toDouble();
            final rect = Rect.fromLTWH(textLeft, 0, size.width, size.height);
            var row = 0;
            while (row < occupiedRows.length &&
                occupiedRows[row].any(
                  (other) => rect.left < other.right + 8 && rect.right > other.left - 8,
                )) {
              row++;
            }
            if (row == occupiedRows.length) {
              occupiedRows.add([]);
            }
            occupiedRows[row].add(rect);
            labels.add(
              _DurationLabel(
                interval: interval,
                name: name,
                color: color,
                left: left,
                right: right,
                clippedLeft: clippedLeft,
                clippedRight: clippedRight,
                text: label,
                size: size,
                textLeft: textLeft,
                row: row,
                forecast: forecast,
                sameTypeForecast: compareSameType,
              ),
            );
          }
          final arrowY = labels.isEmpty ? top : top + occupiedRows.length * rowHeight + 4;
          for (final label in labels) {
            label.textTop = arrowY - 4 - label.size.height - label.row * rowHeight;
          }
          return _IntervalLane(
            labels: labels,
            arrowY: arrowY,
            bottom: labels.isEmpty ? top : arrowY + 8,
          );
        }

        final first = layoutLane(firstIntervals, firstLabel, firstColor, 0);
        final second = layoutLane(
          secondIntervals,
          secondLabel,
          secondColor,
          first.bottom + (first.labels.isEmpty ? 0 : 5),
        );
        final lanes = [first, second];
        final forecast = estimate;
        if (forecast != null &&
            _day(forecast.rangeEndDate) > _day(forecast.startDateFor(sameType: compareSameType))) {
          final name = switch (forecast.type) {
            CycleTimingEstimateType.top => '${compareSameType ? '고점' : '저점'} → 예상 고점',
            CycleTimingEstimateType.bottom => '${compareSameType ? '저점' : '고점'} → 예상 저점',
          };
          // 날짜 축은 과거와 공유하되, 예측을 과거 기록에 섞지 않습니다.
          final next = layoutLane(
            [
              CycleTimingIntervalModel(
                startDate: forecast.startDateFor(sameType: compareSameType),
                endDate: forecast.rangeEndDate,
              ),
            ],
            name,
            estimateColor,
            second.bottom + (lanes.any((lane) => lane.labels.isNotEmpty) ? 5 : 0),
            forecast: forecast,
          );
          if (next.labels.isNotEmpty) lanes.add(next);
        }
        final axisY = lanes.last.bottom + 3;
        final ticks = _calendarTicks(
          firstDate: firstDate,
          startDay: startDay,
          endDay: endDay,
          width: width,
          measure: measure,
        );
        final tickHeight = ticks.fold<double>(
          measure('2026').height,
          (height, tick) => math.max(height, tick.size.height),
        );
        final format = DateFormat('yyyy/MM/dd');
        return SizedBox(
          height: axisY + 7 + tickHeight + 6,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _IntervalPainter(
                      firstDate: firstDate,
                      startDay: startDay,
                      endDay: endDay,
                      lanes: lanes,
                      ticks: ticks,
                      axisY: axisY,
                      guideDays: guideDays,
                    ),
                  ),
                ),
              ),
              for (final lane in lanes)
                for (final label in lane.labels)
                  Positioned(
                    left: label.textLeft,
                    top: label.textTop,
                    width: label.size.width,
                    height: label.size.height,
                    child: Tooltip(
                      message: label.description(format),
                      child: Semantics(
                        label: label.description(format),
                        excludeSemantics: true,
                        child: ColoredBox(
                          color: Colors.white,
                          child: Text(
                            label.text,
                            style: style.copyWith(color: label.color),
                            textScaler: scaler,
                          ),
                        ),
                      ),
                    ),
                  ),
              for (final tick in ticks)
                Positioned(
                  left: tick.left,
                  top: axisY + 7,
                  width: tick.size.width,
                  height: tick.size.height,
                  child: Text(tick.text, style: style, textScaler: scaler),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DurationLabel {
  final CycleTimingIntervalModel interval;
  final String name;
  final Color color;
  final double left;
  final double right;
  final bool clippedLeft;
  final bool clippedRight;
  final String text;
  final Size size;
  final double textLeft;
  final int row;
  final CycleTimingEstimateModel? forecast;
  final bool sameTypeForecast;
  late double textTop;
  _DurationLabel({
    required this.interval,
    required this.name,
    required this.color,
    required this.left,
    required this.right,
    required this.clippedLeft,
    required this.clippedRight,
    required this.text,
    required this.size,
    required this.textLeft,
    required this.row,
    this.forecast,
    this.sameTypeForecast = false,
  });

  String description(DateFormat format) {
    final estimate = forecast;
    final String details;
    if (estimate == null) {
      details =
          '$name\n'
          '${format.format(interval.startDate)} ~ ${format.format(interval.endDate)}\n'
          '전체 ${interval.durationDays}일';
    } else {
      final startsAtTop = sameTypeForecast
          ? estimate.type == CycleTimingEstimateType.top
          : estimate.type == CycleTimingEstimateType.bottom;
      final anchorLabel = startsAtTop ? '등록 고점' : '등록 저점';
      final duration = estimate.durationDaysFor(sameType: sameTypeForecast);
      final range = estimate.durationRangeDaysFor(sameType: sameTypeForecast);
      final nextRange = estimate.durationRangeDaysFor(sameType: false);
      final basis = sameTypeForecast
          ? '등록 지점 사이 ${duration - estimate.estimatedDurationDays}일 + 다음 구간 예상 ${nextRange.startDays}~${nextRange.endDays}일'
          : '과거 평균에 여유 기간을 둔 참고 범위';
      final lastIncluded = estimate.rangeLastIncludedDate;
      details =
          '$name\n'
          '$anchorLabel: ${format.format(interval.startDate)}\n'
          '예상 중심일: ${format.format(estimate.centerDate)}\n'
          '예상 범위: ${format.format(estimate.rangeStartDate)} ~ ${format.format(lastIncluded)}\n'
          '전체 예상 ${range.startDays}~${range.endDays}일\n$basis';
    }
    return '$details${clippedLeft || clippedRight ? '\n빗금은 화면 밖으로 이어지는 구간입니다.' : ''}';
  }
}

class _IntervalLane {
  final List<_DurationLabel> labels;
  final double arrowY;
  final double bottom;
  const _IntervalLane({required this.labels, required this.arrowY, required this.bottom});
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
  final base = calendarDayKey(firstDate);
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
    'year' => [1, 2, 5, 10, 20, 50, 100],
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
      while (calendarDayKey(DateTime.utc(year)) < first) {
        year += step;
      }
      for (; calendarDayKey(DateTime.utc(year)) <= last; year += step) {
        days.add(calendarDayKey(DateTime.utc(year)));
      }
    } else if (unit == 'month') {
      var month = ((start.year * 12 + start.month - 1) / step).ceil() * step;
      int key(int value) => calendarDayKey(DateTime.utc(value ~/ 12, value % 12 + 1));
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

class _IntervalPainter extends CustomPainter {
  final DateTime firstDate;
  final int startDay;
  final int endDay;
  final List<_IntervalLane> lanes;
  final List<_CalendarTick> ticks;
  final double axisY;
  final Set<int>? guideDays;
  const _IntervalPainter({
    required this.firstDate,
    required this.startDay,
    required this.endDay,
    required this.lanes,
    required this.ticks,
    required this.axisY,
    this.guideDays,
  });
  int _day(DateTime date) => calendarDayKey(date) - calendarDayKey(firstDate);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || endDay <= startDay) {
      return;
    }
    double xFor(int day) => (day - startDay) / (endDay - startDay) * size.width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final guides = <int, double>{};
    for (final lane in lanes) {
      for (final label in lane.labels) {
        // 예상 끝점은 등록된 고점/저점이 아니므로 회색 주기 기준선을 만들지 않습니다.
        for (final date in [
          label.interval.startDate,
          if (label.forecast == null) label.interval.endDate,
        ]) {
          final day = _day(date);
          if (day >= startDay && day <= endDay && (guideDays == null || guideDays!.contains(day))) {
            guides[day] = math.max(guides[day] ?? 0, lane.arrowY);
          }
        }
      }
    }
    final guidePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (final guide in guides.entries) {
      final x = xFor(guide.key);
      for (double y = 0; y < guide.value; y += 8) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 4, guide.value)), guidePaint);
      }
    }
    void slash(double x, double y, Paint paint, {required bool left}) {
      final direction = left ? 1.0 : -1.0;
      for (final shift in [3.0, 7.0]) {
        final center = x + direction * shift;
        canvas.drawLine(Offset(center - 1.5, y + 3), Offset(center + 1.5, y - 3), paint);
      }
    }

    for (final lane in lanes) {
      for (final label in lane.labels) {
        final y = lane.arrowY;
        final forecast = label.forecast;
        final paint = Paint()
          ..color = label.color
          ..strokeWidth = 1.5;
        if (forecast != null) {
          final rawRangeStart = xFor(_day(forecast.rangeStartDate));
          final rawRangeEnd = xFor(_day(forecast.rangeEndDate));
          final rangeLeft = rawRangeStart.clamp(0.0, size.width).toDouble();
          final rangeRight = rawRangeEnd.clamp(0.0, size.width).toDouble();
          final connectorEnd = rawRangeStart.clamp(label.left, label.right).toDouble();
          // 출발점에서 예상 범위까지는 점선으로 연결합니다.
          // 평균일 한 점으로 향하는 화살표 대신, 범위 전체에 양방향 화살표를 그립니다.
          for (var x = label.left; x < connectorEnd; x += 9) {
            canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, connectorEnd), y), paint);
          }
          if (rangeRight > rangeLeft) {
            // 위 차트의 예상 범위와 동일한 날짜 경계를 사용합니다.
            canvas.drawRect(
              Rect.fromLTRB(rangeLeft, 0, rangeRight, y + 5),
              Paint()..color = label.color.withValues(alpha: 0.06),
            );
            canvas.drawRect(
              Rect.fromLTRB(rangeLeft, y - 5, rangeRight, y + 5),
              Paint()..color = label.color.withValues(alpha: 0.18),
            );
            canvas.drawLine(Offset(rangeLeft, y), Offset(rangeRight, y), paint);
            final boundaryPaint = Paint()
              ..color = label.color.withValues(alpha: 0.45)
              ..strokeWidth = 0.8;
            for (final boundary in [rawRangeStart, rawRangeEnd]) {
              if (boundary < 0 || boundary > size.width) {
                continue;
              }
              for (double top = 0; top < y - 5; top += 9) {
                canvas.drawLine(
                  Offset(boundary, top),
                  Offset(boundary, math.min(top + 4, y - 5)),
                  boundaryPaint,
                );
              }
            }
            // 긴 전체 기록에서 범위를 실제 날짜보다 넓게 부풀리지 않습니다.
            final headWidth = math.min(4.0, (rangeRight - rangeLeft) / 3);
            final headHeight = math.min(3.0, headWidth);
            if (rawRangeStart >= 0) {
              canvas.drawLine(Offset(rangeLeft, y - 5), Offset(rangeLeft, y + 5), paint);
              canvas.drawLine(
                Offset(rangeLeft, y),
                Offset(rangeLeft + headWidth, y - headHeight),
                paint,
              );
              canvas.drawLine(
                Offset(rangeLeft, y),
                Offset(rangeLeft + headWidth, y + headHeight),
                paint,
              );
            }
            if (rawRangeEnd <= size.width) {
              canvas.drawLine(Offset(rangeRight, y - 5), Offset(rangeRight, y + 5), paint);
              canvas.drawLine(
                Offset(rangeRight, y),
                Offset(rangeRight - headWidth, y - headHeight),
                paint,
              );
              canvas.drawLine(
                Offset(rangeRight, y),
                Offset(rangeRight - headWidth, y + headHeight),
                paint,
              );
            }
          }
          if (label.clippedLeft) {
            slash(label.left, y, paint, left: true);
          } else {
            canvas.drawLine(Offset(label.left, y - 4), Offset(label.left, y + 4), paint);
          }
          if (label.clippedRight) {
            slash(label.right, y, paint, left: false);
          }
          continue;
        }
        canvas.drawLine(Offset(label.left, y), Offset(label.right, y), paint);
        if (label.clippedLeft) {
          slash(label.left, y, paint, left: true);
        } else {
          canvas.drawLine(Offset(label.left, y - 4), Offset(label.left, y + 4), paint);
        }
        if (label.clippedRight) {
          slash(label.right, y, paint, left: false);
        } else {
          canvas.drawLine(Offset(label.right, y), Offset(label.right - 4, y - 3), paint);
          canvas.drawLine(Offset(label.right, y), Offset(label.right - 4, y + 3), paint);
        }
        if (label.row > 0) {
          // 충돌 때문에 위로 옮긴 라벨은 원래 화살표와 연결합니다.
          final anchor = (label.left + label.right) / 2;
          canvas.drawLine(
            Offset(anchor, y - 3),
            Offset(label.textLeft + label.size.width / 2, label.textTop + label.size.height + 1),
            Paint()
              ..color = label.color.withValues(alpha: 0.4)
              ..strokeWidth = 0.8,
          );
        }
      }
    }
    final axisPaint = Paint()
      ..color = const Color(0xFFE4E7EC)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, axisY), Offset(size.width, axisY), axisPaint);
    for (final tick in ticks) {
      canvas.drawLine(Offset(tick.x, axisY), Offset(tick.x, axisY + 3), axisPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IntervalPainter old) =>
      firstDate != old.firstDate ||
      startDay != old.startDay ||
      endDay != old.endDay ||
      lanes != old.lanes ||
      ticks != old.ticks ||
      guideDays != old.guideDays ||
      axisY != old.axisY;
}

// 시각을 UTC로 변환하지 않고, 앱에서 사용하는 달력 날짜를 비교합니다.
int calendarDayKey(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
