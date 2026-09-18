import 'package:btc_horizon/models/cycle_timing_analysis_model.dart';
import 'package:btc_horizon/providers/analysis_date_provider.dart';
import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cycleTimingAnalysisProvider = Provider<CycleTimingAnalysisModel>((ref) {
  final today = ref.watch(analysisDateProvider);
  return calculateCycleTimingAnalysis(today: today);
});
