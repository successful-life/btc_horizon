import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:btc_horizon/models/cycle_timing_comparison_model.dart';

class CycleTimingComparisonChart extends StatelessWidget {
  final CycleTimingComparisonModel comparison;

  const CycleTimingComparisonChart({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    if (comparison.chartPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstDate = comparison.chartPoints.first.date;

    final spots = comparison.chartPoints.map((point) {
      return FlSpot(
        point.date.difference(firstDate).inDays.toDouble(),
        log(point.closePrice) / ln10,
      );
    }).toList();

    final minY = spots.map((spot) => spot.y).reduce(min);
    final maxY = spots.map((spot) => spot.y).reduce(max);

    final equivalentLines = comparison.comparisons.map((item) {
      final x = item.equivalentDate.difference(firstDate).inDays.toDouble();

      return VerticalLine(
        x: x,
        strokeWidth: 1,
        dashArray: [5, 5],
        label: VerticalLineLabel(
          show: true,
          alignment: Alignment.topCenter,
          labelResolver: (_) => '${(comparison.currentProgress * 100).toStringAsFixed(1)}%',
        ),
      );
    }).toList();

    return SizedBox(
      height: 320,
      child: LineChart(
        LineChartData(
          minX: spots.first.x,
          maxX: spots.last.x,
          minY: minY,
          maxY: maxY,

          gridData: const FlGridData(show: true),

          borderData: FlBorderData(show: true),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final date = firstDate.add(Duration(days: value.round()));

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
                  final price = pow(10, value).toDouble();

                  return SideTitleWidget(
                    meta: meta,
                    child: Text(_formatPrice(price), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),

          extraLinesData: ExtraLinesData(verticalLines: equivalentLines),

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

                  final price = pow(10, spot.y).toDouble();

                  return LineTooltipItem(
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n'
                    '\$${price.toStringAsFixed(0)}',
                    const TextStyle(),
                  );
                }).toList();
              },
            ),
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
