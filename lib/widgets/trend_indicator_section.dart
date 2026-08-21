import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:flutter/material.dart';

class TrendIndicatorSection extends StatelessWidget {
  final List<IndicatorSummaryModel> indicators;

  const TrendIndicatorSection({super.key, required this.indicators});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('추세 판단 근거', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        ...indicators.map(
          (indicator) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TrendIndicatorCard(indicator: indicator),
          ),
        ),
      ],
    );
  }
}

class _TrendIndicatorCard extends StatelessWidget {
  final IndicatorSummaryModel indicator;

  const _TrendIndicatorCard({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final status = indicator.status ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Indicator name
          Text(indicator.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),

          const SizedBox(height: 10),

          // 2. Main value
          Text(indicator.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),

          const SizedBox(height: 8),

          // 3. Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
