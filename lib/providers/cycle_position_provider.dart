import 'package:btc_horizon/providers/cycle_indicator_provider.dart';
import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cyclePositionProvider = Provider<double?>((ref) {
  final indicators = ref.watch(cycleIndicatorProvider);

  return calculateCyclePositionScore(indicators: indicators);
});
