import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';

class TrendDetailModel {
  final CycleIndicatorModel summary;
  final TrendChartDataModel chartData;

  TrendDetailModel({required this.summary, required this.chartData});
}
