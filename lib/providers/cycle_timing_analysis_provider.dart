import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:btc_horizon/models/cycle_timing_analysis_model.dart';

final cycleTimingAnalysisProvider = Provider<CycleTimingAnalysisModel>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return calculateCycleTimingAnalysis(today: today);
});
