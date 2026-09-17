import 'package:btc_horizon/enums/bitstamp_symbol.dart';
import 'package:btc_horizon/models/cycle_timing_analysis_chart_model.dart';
import 'package:btc_horizon/providers/bitstamp_ohlc_provider.dart';
import 'package:btc_horizon/providers/cycle_timing_analysis_provider.dart';
import 'package:btc_horizon/utils/cycle_timing_analysis_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleTimingAnalysisChartProvider = Provider<AsyncValue<CycleTimingAnalysisChartModel>>((ref) {
  final analysis = ref.watch(cycleTimingAnalysisProvider);

  final ohlcAsync = ref.watch(bitstampOhlcProvider(BitstampSymbol.btcusd));

  return ohlcAsync.whenData(
    (ohlcList) => buildCycleTimingAnalysisChartData(analysis: analysis, ohlcList: ohlcList),
  );
});
