import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

enum _DragTarget { start, end, window }

/// 전체 가격 흐름 위에서 표시 기간을 조절합니다.
/// 비율만 전달하며, 날짜 선택과 API 조회는 이 위젯이 담당하지 않습니다.
class ChartRangeSelector extends StatefulWidget {
  // X와 Y를 0~1로 변환한 BTC 가격선. null은 데이터 누락 구간입니다.
  final List<Offset?> overviewPoints;
  final RangeValues values;
  final double minimumSpan;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<RangeValues> onChanged;
  // 필요할 때만 사용합니다. 기존 MVRV 호출부는 그대로 동작합니다.
  final VoidCallback? onChangeStart;
  final VoidCallback? onChangeEnd;
  final double height;

  ChartRangeSelector({
    super.key,
    required this.overviewPoints,
    required this.values,
    required this.minimumSpan,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.height = 60,
  }) : assert(minimumSpan > 0 && minimumSpan <= 1),
       assert(values.start >= 0 && values.end <= 1),
       assert(values.end > values.start);

  @override
  State<ChartRangeSelector> createState() => _ChartRangeSelectorState();
}

class _ChartRangeSelectorState extends State<ChartRangeSelector> {
  // 양끝에서도 손잡이를 잡을 수 있도록 바깥 공간을 남깁니다.
  static const _inset = 20.0;
  static final _dateFormat = DateFormat('yyyy/MM/dd');

  _DragTarget? _dragTarget;
  RangeValues? _dragOrigin;
  double _dragStartX = 0;
  double _dragWidth = 1;
  bool _dragActive = false;

  void _startDrag(double x, double width) {
    final startX = _inset + widget.values.start * width;
    final endX = _inset + widget.values.end * width;
    final edgeHitWidth = math.min(20.0, (endX - startX) / 3);

    if (x > startX + edgeHitWidth && x < endX - edgeHitWidth) {
      _dragTarget = _DragTarget.window;
    } else if ((x - startX).abs() <= 24 || (x - endX).abs() <= 24) {
      _dragTarget = (x - startX).abs() <= (x - endX).abs() ? _DragTarget.start : _DragTarget.end;
    } else {
      _dragTarget = _DragTarget.window;
    }
    _dragOrigin = widget.values;
    _dragStartX = x;
    _dragWidth = width;
  }

  void _updateDrag(double x) {
    final origin = _dragOrigin;
    final target = _dragTarget;
    if (origin == null || target == null) {
      return;
    }
    final delta = (x - _dragStartX) / _dragWidth;
    switch (target) {
      case _DragTarget.start:
        _emit(
          RangeValues(
            (origin.start + delta).clamp(0.0, origin.end - widget.minimumSpan).toDouble(),
            origin.end,
          ),
        );
      case _DragTarget.end:
        _emit(
          RangeValues(
            origin.start,
            (origin.end + delta).clamp(origin.start + widget.minimumSpan, 1.0).toDouble(),
          ),
        );
      case _DragTarget.window:
        final span = origin.end - origin.start;
        final start = (origin.start + delta).clamp(0.0, 1.0 - span).toDouble();
        _emit(RangeValues(start, start + span));
    }
  }

  void _finishDrag() {
    final wasActive = _dragActive;
    _dragActive = false;
    _dragOrigin = null;
    _dragTarget = null;
    if (wasActive) widget.onChangeEnd?.call();
  }

  void _jumpTo(double x, double width) {
    final ratio = ((x - _inset) / width).clamp(0.0, 1.0).toDouble();
    if (ratio >= widget.values.start && ratio <= widget.values.end) {
      return;
    }
    final span = widget.values.end - widget.values.start;
    final start = (ratio - span / 2).clamp(0.0, 1.0 - span).toDouble();
    _emit(RangeValues(start, start + span));
  }

  void _emit(RangeValues values) {
    if (values != widget.values) {
      widget.onChanged(values);
    }
  }

  String _dateLabel(double ratio) {
    final days = widget.lastDate.difference(widget.firstDate).inDays;
    return _dateFormat.format(widget.firstDate.add(Duration(days: (days * ratio).round())));
  }

  Widget _accessibleHandle({required bool isStart}) {
    final values = widget.values;
    final current = isStart ? values.start : values.end;
    final step = math.max(widget.minimumSpan / 10, 0.01);
    final minimum = isStart ? 0.0 : values.start + widget.minimumSpan;
    final maximum = isStart ? values.end - widget.minimumSpan : 1.0;
    final increase = (current + step).clamp(minimum, maximum).toDouble();
    final decrease = (current - step).clamp(minimum, maximum).toDouble();

    void change(double next) {
      _emit(isStart ? RangeValues(next, values.end) : RangeValues(values.start, next));
    }

    return Semantics(
      label: isStart ? '표시 시작일' : '표시 종료일',
      value: _dateLabel(current),
      increasedValue: _dateLabel(increase),
      decreasedValue: _dateLabel(decrease),
      onIncrease: increase > current ? () => change(increase) : null,
      onDecrease: decrease < current ? () => change(decrease) : null,
      child: const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(1.0, constraints.maxWidth - _inset * 2);
          return Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _OverviewPainter(
                      points: widget.overviewPoints,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      inset: _inset,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('chart-range-gesture'),
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  // 가로 드래그만 처리해 상위 화면의 세로 스크롤을 방해하지 않습니다.
                  onHorizontalDragDown: (details) => _startDrag(details.localPosition.dx, width),
                  // 단순 터치나 세로 스크롤에는 시작 알림을 보내지 않습니다.
                  onHorizontalDragStart: (_) {
                    _dragActive = true;
                    widget.onChangeStart?.call();
                  },
                  onHorizontalDragUpdate: (details) => _updateDrag(details.localPosition.dx),
                  onHorizontalDragEnd: (_) => _finishDrag(),
                  onHorizontalDragCancel: _finishDrag,
                  onTapUp: (details) => _jumpTo(details.localPosition.dx, width),
                  child: CustomPaint(
                    painter: _SelectionPainter(values: widget.values, inset: _inset),
                  ),
                ),
              ),
              for (final isStart in [true, false])
                Positioned(
                  left: _inset + width * (isStart ? widget.values.start : widget.values.end) - 20,
                  top: 0,
                  bottom: 0,
                  width: 40,
                  child: IgnorePointer(child: _accessibleHandle(isStart: isStart)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewPainter extends CustomPainter {
  final List<Offset?> points;
  final DateTime firstDate;
  final DateTime lastDate;
  final double inset;

  _OverviewPainter({
    required this.points,
    required this.firstDate,
    required this.lastDate,
    required this.inset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(inset, 4, math.max(1.0, size.width - inset * 2), size.height - 8);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF1F5F9));

    final path = Path();
    var needsMove = true;
    for (final point in points) {
      if (point == null) {
        needsMove = true;
        continue;
      }
      final x = rect.left + point.dx * rect.width;
      final y = rect.top + 3 + (1 - point.dy) * (rect.height - 17);
      if (needsMove) {
        path.moveTo(x, y);
        needsMove = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF54768A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final days = lastDate.difference(firstDate).inDays;
    final divisions = rect.width >= 480 ? 4 : 2;
    for (var i = 0; i <= divisions; i++) {
      final ratio = i / divisions;
      final date = firstDate.add(Duration(days: (days * ratio).round()));
      final label = days > 730
          ? '${date.year}'
          : '${date.year}.${date.month.toString().padLeft(2, '0')}';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF667085)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (rect.left + rect.width * ratio - text.width / 2)
          .clamp(rect.left + 2, rect.right - text.width - 2)
          .toDouble();
      text.paint(canvas, Offset(x, rect.bottom - text.height - 1));
      text.dispose();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OverviewPainter oldDelegate) {
    return !identical(points, oldDelegate.points) ||
        firstDate != oldDelegate.firstDate ||
        lastDate != oldDelegate.lastDate ||
        inset != oldDelegate.inset;
  }
}

class _SelectionPainter extends CustomPainter {
  final RangeValues values;
  final double inset;

  _SelectionPainter({required this.values, required this.inset});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(inset, 4, math.max(1.0, size.width - inset * 2), size.height - 8);
    final left = rect.left + rect.width * values.start;
    final right = rect.left + rect.width * values.end;
    final selected = Rect.fromLTRB(left, rect.top, right, rect.bottom);

    canvas.drawRect(
      Rect.fromLTRB(rect.left, rect.top, left, rect.bottom),
      Paint()..color = Colors.white.withValues(alpha: 0.60),
    );
    canvas.drawRect(
      Rect.fromLTRB(right, rect.top, rect.right, rect.bottom),
      Paint()..color = Colors.white.withValues(alpha: 0.60),
    );
    canvas.drawRect(selected, Paint()..color = const Color(0xFF4A86D4).withValues(alpha: 0.12));
    canvas.drawRect(
      selected,
      Paint()
        ..color = const Color(0xFF7B9EC9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (final x in [left, right]) {
      final handle = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, rect.center.dy), width: 12, height: 26),
        const Radius.circular(3),
      );
      canvas.drawRRect(handle, Paint()..color = Colors.white);
      canvas.drawRRect(
        handle,
        Paint()
          ..color = const Color(0xFF7B9EC9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      for (final shift in [-1.5, 1.5]) {
        canvas.drawLine(
          Offset(x + shift, rect.center.dy - 5),
          Offset(x + shift, rect.center.dy + 5),
          Paint()
            ..color = const Color(0xFF667085)
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return values != oldDelegate.values || inset != oldDelegate.inset;
  }
}
