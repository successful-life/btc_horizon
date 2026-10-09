import 'package:btc_horizon/providers/cycle_timing_comparison_provider.dart';
import 'package:btc_horizon/models/cycle_timing_comparison_model.dart';
import 'package:btc_horizon/screens/cycle_timing_comparison_fullscreen_screen.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_chart.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_style.dart';
import 'package:btc_horizon/widgets/cycle_timing_progress.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CycleTimingComparisonSection extends ConsumerStatefulWidget {
  const CycleTimingComparisonSection({super.key});

  @override
  ConsumerState<CycleTimingComparisonSection> createState() => _CycleTimingComparisonSectionState();
}

class _CycleTimingComparisonSectionState extends ConsumerState<CycleTimingComparisonSection> {
  CycleTimingComparisonChartView? _view;
  int _viewRevision = 0;

  Future<void> _openFullscreen(CycleTimingComparisonModel comparison) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CycleTimingComparisonFullscreenScreen(
          comparison: comparison,
          initialView: _view,
          onViewChanged: (view) => _view = view,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    // 확대 화면에서 바꾼 기간/날짜를 일반 화면에도 적용합니다.
    setState(() => _viewRevision++);
  }

  @override
  Widget build(BuildContext context) {
    final comparisonAsync = ref.watch(cycleTimingComparisonProvider);

    // 로딩·오류 중에도 카드의 제목과 배경은 유지합니다.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '반감기 사이클',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CycleTimingComparisonStyle.text,
            ),
          ),
          const SizedBox(height: 16),
          comparisonAsync.when(
            data: (comparison) {
              final percentage = (comparison.currentProgress * 100).toStringAsFixed(1);
              final hasChart = comparison.chartPoints.isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CycleTimingProgress(comparison: comparison),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: CycleTimingComparisonStyle.divider),
                  const SizedBox(height: 20),
                  const Text(
                    '과거 사이클과 비교',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CycleTimingComparisonStyle.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '주황색 점선은 각 사이클의 $percentage% 지점입니다.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: CycleTimingComparisonStyle.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CycleTimingComparisonChart(
                    key: ValueKey(_viewRevision),
                    comparison: comparison,
                    initialView: _view,
                    onViewChanged: (view) => _view = view,
                    onExpand: () => _openFullscreen(comparison),
                  ),
                  if (hasChart) ...[
                    const SizedBox(height: 12),
                    Text(
                      '가격 기준일 · ${DateFormat('yyyy/MM/dd').format(comparison.chartPoints.last.date)}',
                      style: const TextStyle(fontSize: 11, color: CycleTimingComparisonStyle.muted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    '현재 진행률은 다음 반감기 예상일을 기준으로 계산합니다.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: CycleTimingComparisonStyle.muted,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(color: CycleTimingComparisonStyle.progress),
              ),
            ),
            error: (error, stackTrace) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '반감기 사이클 비교 데이터를 불러오지 못했습니다.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: CycleTimingComparisonStyle.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
