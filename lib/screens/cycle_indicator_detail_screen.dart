import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/providers/cycle_indicator_provider.dart';
import 'package:btc_horizon/widgets/cycle_indicator_detail_header.dart';
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
      CycleIndicatorType.sentiment => indicators.sentiment,

      CycleIndicatorType.cycleTiming => throw StateError(
        'Cycle Timing uses CycleTimingDetailScreen.',
      ),

      CycleIndicatorType.trend => throw StateError('Trend uses TrendDetailScreen.'),
    };

    return Scaffold(
      appBar: AppBar(title: Text('${cycleIndicatorModel.title} 상세')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CycleIndicatorDetailHeader(cycleIndicatorModel: cycleIndicatorModel),

            const SizedBox(height: 20),

            IndicatorTable(indicators: cycleIndicatorModel.indicators),

            const SizedBox(height: 20),

            const Text('해석 영역(임시)'),

            const SizedBox(height: 20),

            const Text('업데이트 날짜 영역(임시)'),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
