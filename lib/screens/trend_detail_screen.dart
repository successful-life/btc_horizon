import 'package:btc_horizon/providers/trend_provider.dart';
import 'package:btc_horizon/widgets/trend_chart.dart';
import 'package:btc_horizon/widgets/trend_indicator_section.dart';
import 'package:btc_horizon/widgets/trend_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrendDetailScreen extends ConsumerWidget {
  const TrendDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(trendProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('추세 상세')),
      body: trendAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return const Center(child: Text('추세 데이터를 불러오지 못했습니다.'));
        },
        data: (trendDetailModel) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TrendChart(data: trendDetailModel.chartData),
                const SizedBox(height: 12),

                TrendLegend(),

                const SizedBox(height: 20),

                TrendIndicatorSection(indicators: trendDetailModel.summary.indicators),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
