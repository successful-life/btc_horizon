import 'package:btc_horizon/models/cycle_timing_analysis_chart_model.dart';
import 'package:btc_horizon/models/cycle_timing_interval_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:intl/intl.dart';

enum _IntervalMode { sameType, alternating }

class CycleTimingAnalysisChart extends StatefulWidget {
  final CycleTimingAnalysisChartModel data;

  const CycleTimingAnalysisChart({super.key, required this.data});

  @override
  State<CycleTimingAnalysisChart> createState() => _CycleTimingAnalysisChartState();
}

class _CycleTimingAnalysisChartState extends State<CycleTimingAnalysisChart> {
  // 이번 요청의 고점→고점·저점→저점을 기본 화면으로 사용한다.
  _IntervalMode _mode = _IntervalMode.sameType;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.pricePoints.length < 2) {
      return const Text('차트를 그릴 가격 데이터가 부족합니다.');
    }

    final analysis = data.analysis;
    final firstDate = data.pricePoints.first.date;
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurfaceVariant;

    const leftAxisWidth = 56.0;
    const currentColor = Colors.blueGrey;
    const estimateColor = Colors.deepPurple;
    const priceColor = Colors.cyan;

    final spots = data.pricePoints.map((point) {
      return FlSpot(_dateToX(point.date, firstDate), math.log(point.closePrice) / math.ln10);
    }).toList();

    final minX = spots.first.x;
    final currentX = _dateToX(analysis.asOfDate, firstDate);
    final estimate = analysis.targetEstimate;
    final estimateStartX = _dateToX(estimate.rangeStartDate, firstDate);
    final estimateEndX = _dateToX(estimate.rangeEndDate, firstDate);
    final estimateCenterX = _dateToX(estimate.centerDate, firstDate);

    // 미래에는 날짜 범위만 표시한다. 가격선은 마지막 실제 데이터에서 끝난다.
    final maxX = math.max(math.max(spots.last.x, currentX), estimateEndX) + 30;
    final minY = spots.map((point) => point.y).reduce(math.min) - 0.12;
    final maxY = spots.map((point) => point.y).reduce(math.max) + 0.18;

    final (
      firstIntervals,
      secondIntervals,
      firstLabel,
      secondLabel,
      firstColor,
      secondColor,
    ) = switch (_mode) {
      _IntervalMode.sameType => (
        data.topToTopIntervals,
        data.bottomToBottomIntervals,
        '고점 → 고점',
        '저점 → 저점',
        Colors.orange,
        Colors.blue,
      ),
      _IntervalMode.alternating => (
        analysis.bottomToTopIntervals,
        analysis.topToBottomIntervals,
        '저점 → 고점',
        '고점 → 저점',
        Colors.green,
        Colors.red,
      ),
    };

    // 진행 중인 구간을 완료된 과거 구간처럼 표시하지 않는다.
    List<CycleTimingIntervalModel> completed(List<CycleTimingIntervalModel> intervals) => intervals
        .where((interval) => _dayKey(interval.endDate) <= _dayKey(analysis.asOfDate))
        .toList();

    final firstCompleted = completed(firstIntervals);
    final secondCompleted = completed(secondIntervals);
    final rangeStartX = math.max(minX, estimateStartX);
    final rangeEndX = math.min(maxX, estimateEndX);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<_IntervalMode>(
          value: _mode,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: _IntervalMode.sameType, child: Text('고점 → 고점 · 저점 → 저점')),
            DropdownMenuItem(value: _IntervalMode.alternating, child: Text('저점 → 고점 · 고점 → 저점')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _mode = value);
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            children: [
              SizedBox(
                height: 260,
                child: LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    clipData: const FlClipData.all(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: textColor.withValues(alpha: 0.15), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: leftAxisWidth,
                          interval: 1,
                          minIncluded: false,
                          maxIncluded: false,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatPrice(math.pow(10, value).toDouble()),
                              style: TextStyle(fontSize: 10, color: textColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        color: priceColor,
                        barWidth: 2,
                        isCurved: false,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    extraLinesData: ExtraLinesData(
                      verticalLines: [
                        VerticalLine(
                          x: currentX,
                          color: currentColor,
                          strokeWidth: 1.2,
                          dashArray: [3, 4],
                        ),
                        if (estimateCenterX >= minX && estimateCenterX <= maxX)
                          VerticalLine(
                            x: estimateCenterX,
                            color: estimateColor,
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                          ),
                      ],
                    ),
                    rangeAnnotations: RangeAnnotations(
                      verticalRangeAnnotations: [
                        if (rangeEndX > rangeStartX)
                          VerticalRangeAnnotation(
                            x1: rangeStartX,
                            x2: rangeEndX,
                            color: estimateColor.withValues(alpha: 0.12),
                          ),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touchedSpots) => touchedSpots
                            .map(
                              (spot) => LineTooltipItem(
                                '${DateFormat('yyyy/MM/dd').format(DateTime(firstDate.year, firstDate.month, firstDate.day + spot.x.round()))}\n${_formatPrice(math.pow(10, spot.y).toDouble(), compact: false)}',
                                const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  duration: Duration.zero,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: leftAxisWidth),
                child: Semantics(
                  label:
                      '$firstLabel: ${firstCompleted.map((i) => '${i.durationDays}일').join(', ')}. $secondLabel: ${secondCompleted.map((i) => '${i.durationDays}일').join(', ')}',
                  child: SizedBox(
                    height: 108,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _IntervalPainter(
                        firstDate: firstDate,
                        minX: minX,
                        maxX: maxX,
                        firstIntervals: firstCompleted,
                        secondIntervals: secondCompleted,
                        firstColor: firstColor,
                        secondColor: secondColor,
                        textColor: textColor,
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendItem(color: firstColor, label: firstLabel),
            _LegendItem(color: secondColor, label: secondLabel),
            const _LegendItem(color: priceColor, label: 'BTC 종가'),
            const _LegendItem(color: currentColor, label: '기준일', dashed: true),
            const _LegendItem(color: estimateColor, label: '예상 중심일', dashed: true),
            _LegendItem(
              color: estimateColor.withValues(alpha: 0.12),
              label: '예상 범위',
              isRange: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isRange;
  final bool dashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isRange = false,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 10,
          child: isRange
              ? ColoredBox(color: color)
              : Center(
                  child: dashed
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (int i = 0; i < 3; i++)
                              SizedBox(width: 5, height: 2, child: ColoredBox(color: color)),
                          ],
                        )
                      : SizedBox(height: 2, width: 20, child: ColoredBox(color: color)),
                ),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _IntervalPainter extends CustomPainter {
  final DateTime firstDate;
  final double minX;
  final double maxX;
  final List<CycleTimingIntervalModel> firstIntervals;
  final List<CycleTimingIntervalModel> secondIntervals;
  final Color firstColor;
  final Color secondColor;
  final Color textColor;
  final Color backgroundColor;

  const _IntervalPainter({
    required this.firstDate,
    required this.minX,
    required this.maxX,
    required this.firstIntervals,
    required this.secondIntervals,
    required this.firstColor,
    required this.secondColor,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || maxX <= minX) return;

    double xFor(DateTime date) => (_dateToX(date, firstDate) - minX) / (maxX - minX) * size.width;

    void drawText(String text, double centerX, double top, Color color) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 10, color: color),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: size.width);

      final left = (centerX - painter.width / 2)
          .clamp(0.0, math.max(0.0, size.width - painter.width))
          .toDouble();
      final rect = Rect.fromLTWH(left - 2, top - 1, painter.width + 4, painter.height + 2);
      canvas.drawRect(rect, Paint()..color = backgroundColor);
      painter.paint(canvas, Offset(left, top));
    }

    void drawIntervals(List<CycleTimingIntervalModel> intervals, double y, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5;

      for (final interval in intervals) {
        final startX = xFor(interval.startDate);
        final endX = xFor(interval.endDate);

        // 잘린 구간에 전체 일수를 붙여 표시하지 않는다.
        if (startX < 0 || endX > size.width || endX <= startX) continue;

        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
        canvas.drawLine(Offset(startX, y - 4), Offset(startX, y + 4), paint);
        canvas.drawLine(Offset(endX, y), Offset(endX - 4, y - 3), paint);
        canvas.drawLine(Offset(endX, y), Offset(endX - 4, y + 3), paint);
        drawText('${interval.durationDays}일', (startX + endX) / 2, y - 17, color);
      }
    }

    drawIntervals(firstIntervals, 24, firstColor);
    drawIntervals(secondIntervals, 56, secondColor);

    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 78), Offset(size.width, 78), axisPaint);

    final lastYear = DateTime(firstDate.year, firstDate.month, firstDate.day + maxX.ceil()).year;
    final yearStep = size.width >= 260 ? 2 : 4;

    for (int year = firstDate.year; year <= lastYear; year++) {
      if (year % yearStep != 0) continue;
      final x = xFor(DateTime(year, 1, 1));
      if (x < 0 || x > size.width) continue;

      canvas.drawLine(Offset(x, 78), Offset(x, 82), axisPaint);
      drawText(year.toString(), x, 87, textColor);
    }
  }

  @override
  bool shouldRepaint(covariant _IntervalPainter oldDelegate) =>
      firstDate != oldDelegate.firstDate ||
      minX != oldDelegate.minX ||
      maxX != oldDelegate.maxX ||
      firstIntervals != oldDelegate.firstIntervals ||
      secondIntervals != oldDelegate.secondIntervals ||
      firstColor != oldDelegate.firstColor ||
      secondColor != oldDelegate.secondColor ||
      textColor != oldDelegate.textColor ||
      backgroundColor != oldDelegate.backgroundColor;
}

int _dayKey(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

double _dateToX(DateTime date, DateTime firstDate) =>
    (_dayKey(date) - _dayKey(firstDate)).toDouble();

String _formatPrice(double price, {bool compact = true}) {
  if (!compact) return '\$${price.toStringAsFixed(0)}';
  if (price >= 1000000) {
    return '\$${(price / 1000000).toStringAsFixed(1)}M';
  }
  if (price >= 1000) return '\$${(price / 1000).toStringAsFixed(0)}K';
  return '\$${price.toStringAsFixed(0)}';
}
