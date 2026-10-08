import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';
import 'package:btc_horizon/models/cycle_timing_analysis_chart_model.dart';
import 'package:btc_horizon/providers/cycle_timing_analysis_chart_provider.dart';
import 'package:btc_horizon/providers/cycle_timing_analysis_provider.dart';
import 'package:btc_horizon/screens/cycle_timing_fullscreen_screen.dart';
import 'package:btc_horizon/widgets/cycle_timing_analysis_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CycleTimingAnalysisSection extends ConsumerStatefulWidget {
  const CycleTimingAnalysisSection({super.key});

  @override
  ConsumerState<CycleTimingAnalysisSection> createState() => _CycleTimingAnalysisSectionState();
}

class _CycleTimingAnalysisSectionState extends ConsumerState<CycleTimingAnalysisSection> {
  CycleTimingChartView? _view;
  int _viewRevision = 0;

  Future<void> _openFullscreen(CycleTimingAnalysisChartModel data) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CycleTimingFullscreenScreen(
          data: data,
          initialView: _view,
          // 확대 화면과 일반 화면에서 같은 표시 상태를 이어갑니다.
          onViewChanged: (view) => _view = view,
        ),
      ),
    );
    if (mounted) setState(() => _viewRevision++);
  }

  @override
  Widget build(BuildContext context) {
    // 날짜 분석 요약은 가격 조회 상태와 관계없이 표시합니다.
    final analysis = ref.watch(cycleTimingAnalysisProvider);
    final chartAsync = ref.watch(cycleTimingAnalysisChartProvider);
    final theme = Theme.of(context);
    final format = DateFormat('yyyy/MM/dd');
    final estimate = analysis.targetEstimate;
    final estimateLabel = estimate.type == CycleTimingEstimateType.top ? '예상 고점' : '예상 저점';
    // 계산은 [start, end), 화면에는 실제 포함되는 마지막 날짜를 표시합니다.
    final lastIncludedDate = DateTime(
      estimate.rangeEndDate.year,
      estimate.rangeEndDate.month,
      estimate.rangeEndDate.day - 1,
    );
    final dateStyle = theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF667085));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '고·저점 주기 분석',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF172033)),
          ),
          const SizedBox(height: 12),
          Text(
            '$estimateLabel 범위: ${format.format(estimate.rangeStartDate)} ~ ${format.format(lastIncludedDate)}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('예상 중심일: ${format.format(estimate.centerDate)}', style: dateStyle),
          const SizedBox(height: 4),
          Text('현재 점수 구간: ${analysis.status}', style: dateStyle),
          const SizedBox(height: 4),
          Text('분석 기준일: ${format.format(analysis.asOfDate)}', style: dateStyle),
          const SizedBox(height: 12),
          chartAsync.when(
            loading: () =>
                const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('가격 차트를 불러오지 못했습니다.'),
            ),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CycleTimingAnalysisChart(
                  key: ValueKey(_viewRevision),
                  data: data,
                  initialView: _view,
                  onViewChanged: (view) => _view = view,
                  onExpand: () => _openFullscreen(data),
                ),
                if (data.pricePoints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('가격 기준일: ${format.format(data.pricePoints.last.date)}', style: dateStyle),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('과거 고·저점 간 소요 기간으로 예상 날짜 범위를 계산합니다.', style: dateStyle),
        ],
      ),
    );
  }
}
