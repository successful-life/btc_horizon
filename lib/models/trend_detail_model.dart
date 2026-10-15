import 'package:btc_horizon/enums/trend_status.dart';
import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';

class TrendReference {
  final TrendStatus status;
  final double price;
  final DateTime receivedAt;
  final DateTime weekStart;
  final double baselineValue;
  final bool isLive, isProvisional;
  const TrendReference({
    required this.status,
    required this.price,
    required this.receivedAt,
    required this.weekStart,
    required this.baselineValue,
    required this.isLive,
    required this.isProvisional,
  });
}

class TrendDetailModel {
  final CycleIndicatorModel summary;
  final TrendChartDataModel chartData;
  final TrendReference? reference;
  const TrendDetailModel({
    required this.summary,
    required this.chartData,
    this.reference,
  });
}
