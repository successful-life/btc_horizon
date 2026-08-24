import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/providers/cycle_indicator_provider.dart';
import 'package:btc_horizon/widgets/indicator_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CycleIndicatorDetailScreen extends ConsumerWidget {
  final CycleIndicatorType type;

  const CycleIndicatorDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = ref.watch(cycleIndicatorProvider);

    final cycleIndicatorModel = switch (type) {
      CycleIndicatorType.valuation => indicators.valuation,
      CycleIndicatorType.cycleTiming => indicators.cycleTiming,
      CycleIndicatorType.sentiment => indicators.sentiment,
      CycleIndicatorType.trend => throw StateError('Trend uses TrendDetailScreen.'),
    };

    final categoryScoreText = cycleIndicatorModel.score == null
        ? '-'
        : cycleIndicatorModel.score!.toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: Text('${cycleIndicatorModel.title} 상세')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.lightGreenAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.insert_chart_outlined_sharp),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cycleIndicatorModel.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$categoryScoreText / 100'),
                          const SizedBox(height: 10),
                          const Text('저평가 (임시)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Indicator
              IndicatorTable(indicators: cycleIndicatorModel.indicators),

              // 3. Analysis
              const Text('해석 영역(임시)'),
              const SizedBox(height: 20),

              // 4. Update Date
              const Text('업데이트 날짜 영역(임시)'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
