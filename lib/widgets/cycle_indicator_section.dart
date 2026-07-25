import 'package:btc_horizon/providers/cycle_indicator_provider.dart';
import 'package:btc_horizon/screens/cycle_indicator_detail_screen.dart';
import 'package:btc_horizon/widgets/cycle_indicator_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CycleIndicatorSection extends ConsumerWidget {
  const CycleIndicatorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = ref.watch(cycleIndicatorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('사이클 지표', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: [
                // 1. Valuation Card
                Expanded(
                  child: CycleIndicatorCard(
                    icon: Icons.insert_chart_outlined_sharp,
                    title: indicators.valuation.title,
                    scoreText: indicators.valuation.score?.round().toString() ?? '-',
                    valueColor: Colors.green.shade900,
                    bgColor: const Color(0xFFE6F7D8),
                    iconColor: Colors.green.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CycleIndicatorDetailScreen(cycleIndicatorModel: indicators.valuation),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 2. Cycle Timing Card
                Expanded(
                  child: CycleIndicatorCard(
                    icon: Icons.date_range,
                    title: indicators.cycleTiming.title,
                    scoreText: indicators.cycleTiming.score?.round().toString() ?? '-',
                    valueColor: Colors.orange.shade900,
                    bgColor: const Color(0xFFFFE2A8),
                    iconColor: Colors.orange.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CycleIndicatorDetailScreen(
                            cycleIndicatorModel: indicators.cycleTiming,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 3. trend Card
                Expanded(
                  child: CycleIndicatorCard(
                    icon: Icons.show_chart,
                    title: indicators.trend.title,
                    scoreText: indicators.trend.score?.round().toString() ?? '-',
                    valueColor: Colors.indigo.shade900,
                    bgColor: const Color(0xFFE1E6FF),
                    iconColor: Colors.indigo.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CycleIndicatorDetailScreen(cycleIndicatorModel: indicators.trend),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 4. Sentiment / Leverage Card
                Expanded(
                  child: CycleIndicatorCard(
                    icon: Icons.show_chart,
                    title: indicators.sentiment.title,
                    scoreText: indicators.sentiment.score?.round().toString() ?? '-',
                    valueColor: Colors.red.shade900,
                    bgColor: const Color.fromARGB(255, 249, 169, 169),
                    iconColor: Colors.red.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CycleIndicatorDetailScreen(cycleIndicatorModel: indicators.sentiment),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
