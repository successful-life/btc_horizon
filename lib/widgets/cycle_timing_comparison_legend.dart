import 'package:flutter/material.dart';

import 'package:btc_horizon/widgets/cycle_timing_comparison_style.dart';

class CycleTimingComparisonLegend extends StatelessWidget {
  final bool showPrice;
  final bool showHalving;
  final bool showProgress;
  final bool showRange;
  const CycleTimingComparisonLegend({
    super.key,
    this.showPrice = true,
    this.showHalving = true,
    this.showProgress = true,
    this.showRange = true,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      if (showPrice) const _LegendItem(label: 'BTC 종가', color: CycleTimingComparisonStyle.price),
      if (showHalving) const _LegendItem(label: '반감기', color: CycleTimingComparisonStyle.halving),
      if (showProgress)
        const _LegendItem(
          label: '동일 진행률',
          color: CycleTimingComparisonStyle.progress,
          type: _LegendType.dashed,
        ),
      if (showRange)
        const _LegendItem(
          label: '진행 구간',
          color: CycleTimingComparisonStyle.currentRange,
          type: _LegendType.range,
        ),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final _LegendType type;

  const _LegendItem({required this.label, required this.color, this.type = _LegendType.line});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: SizedBox(
          width: 16,
          height: 10,
          child: switch (type) {
            _LegendType.line => Center(child: Container(height: 1.5, color: color)),
            _LegendType.dashed => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 3; i++) Container(width: 4, height: 1.5, color: color),
              ],
            ),
            _LegendType.range => DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
          },
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: CycleTimingComparisonStyle.muted)),
    ],
  );
}

enum _LegendType { line, dashed, range }
