import 'package:btc_horizon/models/cycle_timing_comparison_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CycleTimingProgress extends StatelessWidget {
  final CycleTimingComparisonModel comparison;

  const CycleTimingProgress({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    const progressColor = Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '현재 반감기 사이클 진행률',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(comparison.currentProgress * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),

        const SizedBox(height: 16),

        LinearProgressIndicator(
          color: progressColor,
          backgroundColor: progressColor.withValues(alpha: 0.15),
          value: comparison.currentProgress.clamp(0.0, 1.0).toDouble(),
          minHeight: 8,
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('yyyy/MM/dd').format(comparison.currentCycle.startDate)),
                const SizedBox(height: 4),
                const Text('반감기 시작', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('yyyy/MM/dd').format(comparison.currentCycle.endDate)),
                const SizedBox(height: 4),
                const Text(
                  '다음 반감기 예상',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w100),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          '기준일: ${DateFormat('yyyy/MM/dd').format(comparison.asOfDate)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
