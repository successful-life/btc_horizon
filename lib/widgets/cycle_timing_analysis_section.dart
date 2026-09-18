import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';
import 'package:btc_horizon/providers/cycle_timing_analysis_chart_provider.dart';
import 'package:btc_horizon/providers/cycle_timing_analysis_provider.dart';
import 'package:btc_horizon/widgets/cycle_timing_analysis_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CycleTimingAnalysisSection extends ConsumerWidget {
  const CycleTimingAnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 가격 조회와 관계없이 계산되는 날짜 분석 결과
    final analysis = ref.watch(cycleTimingAnalysisProvider);

    // 날짜 분석 결과와 가격 데이터를 결합한 차트 데이터
    final chartAsync = ref.watch(cycleTimingAnalysisChartProvider);

    final theme = Theme.of(context);
    final format = DateFormat('yyyy/MM/dd');

    final estimate = analysis.targetEstimate;

    final estimateLabel = switch (estimate.type) {
      CycleTimingEstimateType.top => '예상 고점',
      CycleTimingEstimateType.bottom => '예상 저점',
    };

    // 내부 계산은 [start, end).
    // 화면에는 실제 포함되는 마지막 날짜를 표시한다.
    final lastIncludedDate = DateTime(
      estimate.rangeEndDate.year,
      estimate.rangeEndDate.month,
      estimate.rangeEndDate.day - 1,
    );

    final dateTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('고·저점 주기 분석', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        // 날짜 분석 요약은 차트의 로딩·오류와 관계없이 표시한다.
        Text(
          '$estimateLabel 범위: '
          '${format.format(estimate.rangeStartDate)} ~ '
          '${format.format(lastIncludedDate)}',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text('예상 중심일: ${format.format(estimate.centerDate)}', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text('현재 점수 구간: ${analysis.status}', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text('분석 기준일: ${format.format(analysis.asOfDate)}', style: dateTextStyle),
        const SizedBox(height: 12),

        // 가격 데이터가 필요한 영역만 비동기 상태에 따라 표시한다.
        chartAsync.when(
          loading: () =>
              const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('가격 차트를 불러오지 못했습니다.'),
          ),
          data: (chartData) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CycleTimingAnalysisChart(data: chartData),
              const SizedBox(height: 12),
              Text(
                '가격 기준일: '
                '${format.format(chartData.pricePoints.last.date)}',
                style: dateTextStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('과거 고·저점 간 소요 기간으로 예상 날짜 범위를 계산합니다.'),
      ],
    );
  }
}
