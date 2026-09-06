import 'package:btc_horizon/data/cycle_timing_data.dart';
import 'package:btc_horizon/enums/bitstamp_symbol.dart';
import 'package:btc_horizon/models/bitstamp_ohlc_model.dart';
import 'package:btc_horizon/models/cycle_timing_chart_point_model.dart';
import 'package:btc_horizon/models/cycle_timing_comparison_model.dart';
import 'package:btc_horizon/providers/bitstamp_ohlc_provider.dart';
import 'package:btc_horizon/utils/halving_cycle_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleTimingComparisonProvider = Provider<AsyncValue<CycleTimingComparisonModel>>((ref) {
  final bitstampAsync = ref.watch(bitstampOhlcProvider(BitstampSymbol.btcusd));

  final progress = calculateCycleProgress(cycle: currentHalvingCycle, today: DateTime.now());

  final equivalentDates = calculateEquivalentDates(cycles: historicalCycles, progress: progress);

  return bitstampAsync.when(
    data: (ohlcList) {
      final comparisonList = <CycleTimingComparisonItemModel>[];

      final chartPoints = <CycleTimingChartPointModel>[];

      // 차트 hover 성능을 위해 n일 간격으로 다운샘플링
      for (int i = 0; i < ohlcList.length; i += 7) {
        final ohlc = ohlcList[i];

        chartPoints.add(CycleTimingChartPointModel(date: ohlc.openTime, closePrice: ohlc.close));
      }

      for (int i = 0; i < historicalCycles.length; i++) {
        final closePrice = _findClosePrice(ohlcList: ohlcList, targetDate: equivalentDates[i]);

        if (closePrice == null) {
          return AsyncValue.error(
            StateError('Bitstamp OHLC 데이터를 찾을 수 없습니다: ${equivalentDates[i]}'),
            StackTrace.current,
          );
        }

        comparisonList.add(
          CycleTimingComparisonItemModel(
            cycle: historicalCycles[i],
            equivalentDate: equivalentDates[i],
            closePrice: closePrice,
          ),
        );
      }

      return AsyncValue.data(
        CycleTimingComparisonModel(
          currentProgress: progress,
          comparisons: comparisonList,
          chartPoints: chartPoints,
        ),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

double? _findClosePrice({required List<BitstampOhlcModel> ohlcList, required DateTime targetDate}) {
  for (final ohlc in ohlcList) {
    if (ohlc.openTime.year == targetDate.year &&
        ohlc.openTime.month == targetDate.month &&
        ohlc.openTime.day == targetDate.day) {
      return ohlc.close;
    }
  }

  return null;
}
