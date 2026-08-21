class TrendChartDataModel {
  final List<TrendChartPoint> price;
  final List<TrendChartPoint> upperTrendThreshold;
  final List<TrendChartPoint> trendBaseline;
  final List<TrendChartPoint> lowerTrendThreshold;
  final List<TrendChartPoint> bottomRangeBoundary;

  const TrendChartDataModel({
    required this.price,
    required this.upperTrendThreshold,
    required this.trendBaseline,
    required this.lowerTrendThreshold,
    required this.bottomRangeBoundary,
  });
}

class TrendChartPoint {
  final DateTime time;
  final double value;

  const TrendChartPoint({required this.time, required this.value});
}
