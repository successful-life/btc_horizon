import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/providers/funding_rate_provider.dart';
import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:btc_horizon/widgets/cycle_indicator_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CycleIndicatorSection extends ConsumerWidget {
  const CycleIndicatorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fearGreedAsync = ref.watch(fearGreedProvider);
    final mvrvZScoreAsync = ref.watch(mvrvZScoreProvider);
    final fundingRateAsync = ref.watch(fundingRateProvider);

    if (fearGreedAsync.isLoading || mvrvZScoreAsync.isLoading || fundingRateAsync.isLoading) {
      return const SizedBox(height: 200, child: Center(child: Text('사이클 지표 로딩 중...')));
    }

    if (fearGreedAsync.hasError || mvrvZScoreAsync.hasError || fundingRateAsync.hasError) {
      return const SizedBox(height: 200, child: Center(child: Text('사이클 지표 오류')));
    }

    final fearGreedModel = fearGreedAsync.requireValue;
    final mvrvModel = mvrvZScoreAsync.requireValue;
    final fundingRateModel = fundingRateAsync.requireValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('사이클 지표', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              CycleIndicatorCard(
                icon: Icons.speed,
                title: 'Fear & Greed',
                value: fearGreedModel.value.toString(),
                subtitle: fearGreedModel.valueClassification,
                valueColor: Colors.green.shade900,
                bgColor: Colors.lightGreenAccent.shade100,
                iconColor: Colors.green.shade800,
              ),
              const SizedBox(width: 12),
              CycleIndicatorCard(
                icon: Icons.percent,
                title: 'Funding Rate',
                value: '${(fundingRateModel.lastFundingRate * 100).toStringAsFixed(4)}%',
                subtitle: 'BTC/USDT perp',
                valueColor: Colors.orange.shade900,
                bgColor: Colors.orangeAccent.shade100,
                iconColor: Colors.orange.shade800,
              ),
              const SizedBox(width: 12),
              CycleIndicatorCard(
                icon: Icons.show_chart,
                title: 'MVRV Z-Score',
                value: mvrvModel.mvrvZScore.toStringAsFixed(2),
                subtitle: DateFormat('yyyy-MM-dd').format(mvrvModel.timestamp),
                valueColor: Colors.indigo.shade900,
                bgColor: Colors.indigoAccent.shade100,
                iconColor: Colors.indigo.shade800,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
