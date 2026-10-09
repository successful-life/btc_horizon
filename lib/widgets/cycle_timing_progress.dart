import 'package:btc_horizon/models/cycle_timing_comparison_model.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_style.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CycleTimingProgress extends StatelessWidget {
  final CycleTimingComparisonModel comparison;

  const CycleTimingProgress({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy/MM/dd');
    final progress = comparison.currentProgress;
    final percentage = (progress * 100).toStringAsFixed(1);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    Widget endpoint(String label, DateTime date, {bool alignRight = false}) => Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: CycleTimingComparisonStyle.muted)),
        const SizedBox(height: 4),
        Text(
          format.format(date),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CycleTimingComparisonStyle.text,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth / textScale < 220;
        const label = Text(
          '현재 진행률',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CycleTimingComparisonStyle.muted,
          ),
        );
        final value = Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: percentage,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: CycleTimingComparisonStyle.text,
                ),
              ),
              const TextSpan(
                text: '%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: CycleTimingComparisonStyle.muted,
                ),
              ),
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stack)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [label, const SizedBox(height: 4), value],
              )
            else
              Row(
                children: [
                  const Expanded(child: label),
                  const SizedBox(width: 12),
                  value,
                ],
              ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              color: CycleTimingComparisonStyle.progress,
              backgroundColor: CycleTimingComparisonStyle.progressTrack,
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              semanticsLabel: '예상 반감기일 기준 현재 사이클 진행률',
              semanticsValue: '$percentage%',
            ),
            const SizedBox(height: 12),
            if (stack) ...[
              endpoint('최근 반감기', comparison.currentCycle.startDate),
              const SizedBox(height: 12),
              endpoint('다음 반감기 예상', comparison.currentCycle.endDate),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: endpoint('최근 반감기', comparison.currentCycle.startDate)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: endpoint('다음 반감기 예상', comparison.currentCycle.endDate, alignRight: true),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              '분석 기준일 · ${format.format(comparison.asOfDate)}',
              style: const TextStyle(fontSize: 11, color: CycleTimingComparisonStyle.muted),
            ),
          ],
        );
      },
    );
  }
}
