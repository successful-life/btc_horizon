import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendChart extends StatelessWidget {
  final TrendChartDataModel data;

  const TrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (_allPoints.isEmpty) {
      return const Center(child: Text('차트 데이터를 불러오는 중입니다.'));
    }
    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          backgroundColor: Color(0xFF0D0F12),

          minX: _minX,
          maxX: _maxX,
          minY: _minY,
          maxY: _maxY,

          gridData: const FlGridData(show: false),

          borderData: FlBorderData(show: false),

          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          lineTouchData: LineTouchData(enabled: true),

          lineBarsData: [
            _buildLine(points: data.price, barWidth: 3.0, isCurved: false, color: Colors.white),
            _buildLine(
              points: data.upperTrendThreshold,
              barWidth: 1.5,
              isCurved: true,
              color: Colors.pink,
            ),
            _buildLine(
              points: data.trendBaseline,
              barWidth: 2.5,
              isCurved: true,
              color: Colors.amber,
            ),
            _buildLine(
              points: data.lowerTrendThreshold,
              barWidth: 1.5,
              isCurved: true,
              color: Colors.yellow,
            ),
            _buildLine(
              points: data.bottomRangeBoundary,
              barWidth: 1.5,
              isCurved: true,
              color: Colors.cyan,
            ),
          ],
        ),

        transformationConfig: const FlTransformationConfig(
          scaleAxis: FlScaleAxis.horizontal,
          minScale: 1,
          maxScale: 5,
          panEnabled: true,
          scaleEnabled: true,
        ),
      ),
    );
  }

  LineChartBarData _buildLine({
    required List<TrendChartPoint> points,
    required double barWidth,
    required bool isCurved,
    required Color color,
  }) {
    return LineChartBarData(
      spots: points
          .map((point) => FlSpot(point.time.millisecondsSinceEpoch.toDouble(), point.value))
          .toList(),

      isCurved: isCurved,
      barWidth: barWidth,
      color: color,

      dotData: const FlDotData(show: false),

      belowBarData: BarAreaData(show: false),
    );
  }

  List<TrendChartPoint> get _allPoints {
    return [
      ...data.price,
      ...data.trendBaseline,
      ...data.upperTrendThreshold,
      ...data.lowerTrendThreshold,
      ...data.bottomRangeBoundary,
    ];
  }

  double get _minX {
    if (_allPoints.isEmpty) {
      return 0;
    }

    return _allPoints
        .map((point) => point.time.millisecondsSinceEpoch.toDouble())
        .reduce((a, b) => a < b ? a : b);
  }

  double get _maxX {
    if (_allPoints.isEmpty) {
      return 1;
    }

    return _allPoints
        .map((point) => point.time.millisecondsSinceEpoch.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  double get _minY {
    if (_allPoints.isEmpty) {
      return 0;
    }

    return _allPoints.map((point) => point.value).reduce((a, b) => a < b ? a : b);
  }

  double get _maxY {
    if (_allPoints.isEmpty) {
      return 1;
    }

    return _allPoints.map((point) => point.value).reduce((a, b) => a > b ? a : b);
  }
}
