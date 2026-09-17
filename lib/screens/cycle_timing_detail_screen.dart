import 'package:btc_horizon/widgets/cycle_indicator_detail_header.dart';
import 'package:btc_horizon/widgets/cycle_timing_analysis_section.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/providers/cycle_indicator_provider.dart';

class CycleTimingDetailScreen extends ConsumerWidget {
  const CycleTimingDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = ref.watch(cycleIndicatorProvider);
    final cycleTimingModel = indicators.cycleTiming;

    return Scaffold(
      appBar: AppBar(title: const Text('사이클 타이밍 상세')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CycleIndicatorDetailHeader(cycleIndicatorModel: cycleTimingModel),

            const SizedBox(height: 24),

            const CycleTimingAnalysisSection(),

            const SizedBox(height: 24),

            const CycleTimingComparisonSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
