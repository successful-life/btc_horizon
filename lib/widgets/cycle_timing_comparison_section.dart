import 'package:btc_horizon/providers/cycle_timing_comparison_provider.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_chart.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_legend.dart';
import 'package:btc_horizon/widgets/cycle_timing_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CycleTimingComparisonSection extends ConsumerWidget {
  const CycleTimingComparisonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(cycleTimingComparisonProvider);

    return comparisonAsync.when(
      data: (comparison) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            CycleTimingProgress(comparison: comparison),

            const SizedBox(height: 36),

            const Text('반감기 사이클 비교', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

            const SizedBox(height: 16),

            CycleTimingComparisonChart(comparison: comparison),

            CycleTimingComparisonLegend(),

            const SizedBox(height: 20),

            Text(
              '현재 진행률과 동일한 위치를 과거 반감기 사이클에 적용한 결과입니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        );
      },

      loading: () => const Center(child: CircularProgressIndicator()),

      error: (error, stackTrace) => Text('과거 사이클 비교 데이터를 불러오지 못했습니다.'),
    );
  }
}
