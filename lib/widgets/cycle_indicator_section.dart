import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/providers/cycle_indicator_provider.dart';
import 'package:btc_horizon/screens/cycle_indicator_detail_screen.dart';
import 'package:btc_horizon/screens/cycle_timing_detail_screen.dart';
import 'package:btc_horizon/screens/trend_detail_screen.dart';
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
        const Row(
          children: [
            Expanded(
              child: Text(
                '사이클 지표',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172033),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text('100점 기준', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
          ],
        ),
        const SizedBox(height: 8),

        // 네 행이 공유하는 배경과 둥근 테두리
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5EAF1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CycleIndicatorCard(
                icon: Icons.assessment_outlined,
                title: indicators.valuation.title,
                score: indicators.valuation.score,
                iconColor: const Color(0xFF388E50),
                onTap: () {
                  _openDetailScreen(context, CycleIndicatorType.valuation);
                },
              ),
              const _IndicatorDivider(),

              CycleIndicatorCard(
                icon: Icons.schedule_rounded,
                title: indicators.cycleTiming.title,
                score: indicators.cycleTiming.score,
                iconColor: const Color(0xFF258B91),
                onTap: () {
                  _openDetailScreen(context, CycleIndicatorType.cycleTiming);
                },
              ),
              const _IndicatorDivider(),

              CycleIndicatorCard(
                icon: Icons.trending_up_rounded,
                title: indicators.trend.summary.title,
                score: indicators.trend.summary.score,
                iconColor: const Color(0xFF4F5FC4),
                onTap: () {
                  _openDetailScreen(context, CycleIndicatorType.trend);
                },
              ),
              const _IndicatorDivider(),

              CycleIndicatorCard(
                icon: Icons.psychology_outlined,
                title: indicators.sentiment.title,
                score: indicators.sentiment.score,
                iconColor: const Color(0xFFD58A27),
                onTap: () {
                  _openDetailScreen(context, CycleIndicatorType.sentiment);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IndicatorDivider extends StatelessWidget {
  const _IndicatorDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFEDF0F5),
    );
  }
}

void _openDetailScreen(BuildContext context, CycleIndicatorType type) {
  final screen = switch (type) {
    CycleIndicatorType.cycleTiming => const CycleTimingDetailScreen(),

    CycleIndicatorType.trend => const TrendDetailScreen(),

    CycleIndicatorType.valuation ||
    CycleIndicatorType.sentiment => CycleIndicatorDetailScreen(type: type),
  };

  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
