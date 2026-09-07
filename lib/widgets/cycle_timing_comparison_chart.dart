import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:btc_horizon/models/cycle_timing_comparison_model.dart';

class CycleTimingComparisonChart extends StatelessWidget {
  final CycleTimingComparisonModel comparison;

  const CycleTimingComparisonChart({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    if (comparison.chartPoints.isEmpty || comparison.comparisons.isEmpty) {
      return const SizedBox.shrink();
    }

    const progressLineColor = Colors.orange;
    const halvingLineColor = Colors.blueGrey;

    const double logYAxisTopPadding = 0.15;
    const double logYAxisBottomPadding = 0.05;
    const double xAxisRightPaddingDays = 30;

    final firstDate = comparison.chartPoints.first.date;

    final spots = comparison.chartPoints.map((point) {
      return FlSpot(_dateToX(date: point.date, firstDate: firstDate), _priceToY(point.closePrice));
    }).toList();

    final minY = spots.map((spot) => spot.y).reduce(min);
    final maxY = spots.map((spot) => spot.y).reduce(max);

    final currentProgressX = _dateToX(date: comparison.asOfDate, firstDate: firstDate);

    final halvingDates = [
      comparison.comparisons.first.cycle.startDate,
      ...comparison.comparisons.map((item) => item.cycle.endDate),
    ];

    final equivalentLines = comparison.comparisons.map((item) {
      final x = _dateToX(date: item.equivalentDate, firstDate: firstDate);

      return VerticalLine(x: x, color: progressLineColor, strokeWidth: 1);
    }).toList();

    final halvingLines = halvingDates.map((date) {
      final x = _dateToX(date: date, firstDate: firstDate);

      return VerticalLine(x: x, strokeWidth: 1, color: halvingLineColor.withValues(alpha: 0.5));
    }).toList();

    final currentProgressLine = VerticalLine(
      x: currentProgressX,
      color: progressLineColor,
      strokeWidth: 1.5,
    );

    final cycleRanges = comparison.comparisons.map((item) {
      return VerticalRangeAnnotation(
        x1: _dateToX(date: item.cycle.startDate, firstDate: firstDate),
        x2: _dateToX(date: item.equivalentDate, firstDate: firstDate),
        color: halvingLineColor.withValues(alpha: 0.07),
      );
    }).toList();

    final currentCycleRange = VerticalRangeAnnotation(
      x1: _dateToX(date: comparison.currentCycle.startDate, firstDate: firstDate),
      x2: currentProgressX,
      color: halvingLineColor.withValues(alpha: 0.12),
    );

    final maxVisibleX = max(spots.last.x, currentProgressX);

    return SizedBox(
      height: 320,
      child: LineChart(
        LineChartData(
          minX: spots.first.x,
          maxX: maxVisibleX + xAxisRightPaddingDays,

          minY: minY - logYAxisBottomPadding,
          maxY: maxY + logYAxisTopPadding,

          gridData: const FlGridData(show: true, drawVerticalLine: false, drawHorizontalLine: true),

          borderData: FlBorderData(show: true),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 365,
                getTitlesWidget: (value, meta) {
                  final date = firstDate.add(Duration(days: value.round()));

                  if (date.year % 4 != 0) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${date.year}', style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 55,
                getTitlesWidget: (value, meta) {
                  final price = _yToPrice(value);

                  return SideTitleWidget(
                    meta: meta,
                    child: Text(_formatPrice(price), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),

          extraLinesData: ExtraLinesData(
            verticalLines: [...halvingLines, ...equivalentLines, currentProgressLine],
          ),

          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              dotData: const FlDotData(show: false),
              barWidth: 2,
            ),
          ],

          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final date = firstDate.add(Duration(days: spot.x.round()));

                  final price = _yToPrice(spot.y);

                  return LineTooltipItem(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n'
                    '\$${price.toStringAsFixed(0)}',
                    const TextStyle(),
                  );
                }).toList();
              },
            ),
          ),

          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: [...cycleRanges, currentCycleRange],
          ),
        ),
      ),
    );
  }
}

String _formatPrice(double price) {
  if (price >= 1000000) {
    return '\$${(price / 1000000).toStringAsFixed(1)}M';
  }

  if (price >= 1000) {
    return '\$${(price / 1000).toStringAsFixed(0)}K';
  }

  return '\$${price.toStringAsFixed(0)}';
}

double _dateToX({required DateTime date, required DateTime firstDate}) {
  return date.difference(firstDate).inDays.toDouble();
}

double _priceToY(double price) {
  return log(price) / ln10;
}

double _yToPrice(double y) {
  return pow(10, y).toDouble();
}
