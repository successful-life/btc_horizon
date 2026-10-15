import 'package:btc_horizon/enums/trend_status.dart';
import 'package:btc_horizon/models/trend_detail_model.dart';
import 'package:btc_horizon/providers/trend_provider.dart';
import 'package:btc_horizon/widgets/trend_chart.dart';
import 'package:btc_horizon/widgets/trend_chart_style.dart';
import 'package:btc_horizon/widgets/trend_indicator_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrendDetailScreen extends ConsumerWidget {
  const TrendDetailScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(trendProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('추세 상세'),
        backgroundColor: const Color(0xFFF6F7FB),
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final fit =
                box.maxHeight >= 650 &&
                box.maxWidth >= 344 &&
                MediaQuery.textScalerOf(context).scale(12) <= 15;
            final chartHeight = fit ? (box.maxHeight - 80).clamp(552.0, 900.0) + 100 : null;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  trend.when(
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(child: LinearProgressIndicator(minHeight: 2)),
                    ),
                    error: (_, _) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: trendCardDecoration(),
                      child: const Text(
                        '추세 판단 대기 · 연결 상태와 주봉 기록을 확인하고 있습니다.',
                        style: TextStyle(color: trendMuted, fontSize: 12),
                      ),
                    ),
                    data: (detail) => _TrendSummary(detail: detail),
                  ),
                  const SizedBox(height: 8),
                  TrendChartSection(height: chartHeight),
                  const SizedBox(height: 12),
                  if (trend.hasValue) TrendIndicatorSection(detail: trend.requireValue),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrendSummary extends StatelessWidget {
  final TrendDetailModel detail;
  const _TrendSummary({required this.detail});
  @override
  Widget build(BuildContext context) {
    final r = detail.reference;
    if (r == null) return const SizedBox.shrink();
    final label = switch (r.status) {
      TrendStatus.veryBullish => '강한 상승',
      TrendStatus.bullish => '상승',
      TrendStatus.transition => '전환 구간',
      TrendStatus.bearish => '하락',
      TrendStatus.deepBearish => '하락 심화',
      TrendStatus.bottomRange => '장기 저점 영역',
    };
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 2, bottom: 2),
      decoration: trendCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('현재 추세', style: TextStyle(color: trendMuted, fontSize: 12)),
                Text(
                  r.isLive ? label : '판단 대기',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: trendInk,
                  ),
                ),
                Text(
                  '${detail.summary.score?.toStringAsFixed(0) ?? '—'} / 100',
                  style: const TextStyle(color: trendMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '추세 판단 설명',
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) => SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '현재가 기준 추세',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              tooltip: '설명 닫기',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Text(
                          r.isLive
                              ? r.status.description
                              : '수신을 다시 확인하고 있습니다. 기존 차트는 유지하며 점수 산출은 보류합니다.',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '현재 수신 가격과 같은 주봉의 기준선으로 판단합니다. 진행 중인 주봉의 값과 점수는 마감 전까지 달라질 수 있습니다. 과거 봉을 선택해도 현재 추세 점수는 바뀌지 않습니다.',
                          style: TextStyle(fontSize: 12, height: 1.5, color: trendMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
