import 'package:btc_horizon/models/cycle_position_model.dart';
import 'package:btc_horizon/providers/cycle_indicator_provider.dart';
import 'package:btc_horizon/utils/cycle_indicator_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cyclePositionProvider = Provider<CyclePositionModel>((ref) {
  final indicators = ref.watch(cycleIndicatorProvider);

  final cyclePositionScore = calculateCyclePositionScore(indicators: indicators);
  final positionLabel = getCyclePositionLabel(cyclePositionScore: cyclePositionScore);
  final positionDescription = getCyclePositionDescription(cyclePositionScore: cyclePositionScore);
  return CyclePositionModel(
    score: cyclePositionScore,
    title: positionLabel,
    description: positionDescription,
    color: Colors.blue,
  );
});
