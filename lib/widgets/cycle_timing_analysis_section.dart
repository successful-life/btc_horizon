import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';
import 'package:btc_horizon/providers/cycle_timing_analysis_chart_provider.dart';
import 'package:btc_horizon/widgets/cycle_timing_analysis_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CycleTimingAnalysisSection extends ConsumerWidget {
  const CycleTimingAnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(cycleTimingAnalysisChartProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('고·저점 주기 분석', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        chartAsync.when(
          loading: () =>
              const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('분석 차트 데이터를 불러오지 못했습니다.'),
          ),
          data: (data) {
            final analysis = data.analysis;
            final estimate = analysis.targetEstimate;
            final label = switch (estimate.type) {
              CycleTimingEstimateType.top => '예상 고점',
              CycleTimingEstimateType.bottom => '예상 저점',
            };
            final lastIncludedDate = DateTime(
              estimate.rangeEndDate.year,
              estimate.rangeEndDate.month,
              estimate.rangeEndDate.day - 1,
            );

            final format = DateFormat('yyyy/MM/dd');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label 범위: ${format.format(estimate.rangeStartDate)} ~ ${format.format(lastIncludedDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '예상 중심일: ${format.format(estimate.centerDate)}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text('현재 점수 구간: ${analysis.status}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                CycleTimingAnalysisChart(data: data),
                const SizedBox(height: 12),
                Text(
                  '분석 기준일: ${format.format(analysis.asOfDate)}\n가격 기준일: ${format.format(data.pricePoints.last.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text('과거 고·저점 간 소요 기간으로 예상 날짜 범위를 계산합니다.'),

                /*
                Text(
                  '기간은 등록한 고·저점 날짜 사이의 경과 일수입니다. '
                  '종가 선은 실제 고가·저가와 다를 수 있습니다. '
                  '음영은 예상 날짜 범위이며 미래 가격을 의미하지 않습니다. '
                  '범위 종료일은 포함하지 않습니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),*/
              ],
            );
          },
        ),
      ],
    );
  }
}
