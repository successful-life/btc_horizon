import 'package:flutter/material.dart';

class CycleTimingComparisonLegend extends StatelessWidget {
  const CycleTimingComparisonLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _LegendItem(label: '동일 진행률', color: Colors.orange, type: _LegendType.line),
          _LegendItem(label: '비트코인 반감기', color: Colors.blueGrey, type: _LegendType.line),
          _LegendItem(
            label: '진행 구간',
            color: Colors.blueGrey.withValues(alpha: 0.15),
            type: _LegendType.range,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final _LegendType type;

  const _LegendItem({required this.label, required this.color, required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (type) {
          _LegendType.line => Container(width: 18, height: 2, color: color),

          _LegendType.range => Container(
            width: 18,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
        },

        const SizedBox(width: 6),

        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

enum _LegendType { line, range }
