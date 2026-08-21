import 'package:flutter/material.dart';

class TrendLegend extends StatelessWidget {
  const TrendLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(label: 'BTC 가격', color: Colors.white),
        _LegendItem(label: '중·단기 추세 기준선', color: Colors.red),
        _LegendItem(label: '장기 추세 기준선', color: Colors.orange),
        _LegendItem(label: '하락 심화 기준선', color: Colors.yellow),
        _LegendItem(label: '바닥권 진입 기준선', color: Colors.teal),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
