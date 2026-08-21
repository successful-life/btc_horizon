import 'package:btc_horizon/models/binance_kline_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';

String getPriceRelationStatus(double deviationPercent) {
  if (deviationPercent > 0) {
    return '상회';
  }

  if (deviationPercent < 0) {
    return '하회';
  }

  return '동일';
}

List<TrendChartPoint> buildTrendChartPoints({
  required List<BinanceKlineModel> klines,
  required List<double?> values,
}) {
  final points = <TrendChartPoint>[];

  for (int i = 0; i < klines.length; i++) {
    final value = values[i];

    if (value == null) {
      continue;
    }

    points.add(TrendChartPoint(time: klines[i].openTime, value: value));
  }

  return points;
}
