import 'package:btc_horizon/models/trend_chart_data_model.dart';

class WeeklyTrendDataModel {
  final double trendBaseline;
  final double upperTrendThreshold;
  final double lowerTrendThreshold;
  final double bottomRangeBoundary;
  final TrendChartDataModel chartData;

  WeeklyTrendDataModel({
    required this.trendBaseline,
    required this.upperTrendThreshold,
    required this.lowerTrendThreshold,
    required this.bottomRangeBoundary,
    required this.chartData,
  });
}
