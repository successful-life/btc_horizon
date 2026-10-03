import 'package:btc_horizon/providers/mvrv_history_provider.dart';
import 'package:btc_horizon/screens/mvrv_fullscreen_screen.dart';
import 'package:btc_horizon/widgets/mvrv_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MvrvHistorySection extends ConsumerWidget {
  const MvrvHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(mvrvHistoryProvider);

    // 현재 화면에 정상적으로 표시되는 데이터가 있을 때만 확대를 허용합니다.f
    final expandableHistory = !historyAsync.isLoading && !historyAsync.hasError
        ? historyAsync.asData?.value
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'MVRV와 비트코인 가격',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IndicatorInfoIconButton(
                        title: 'MVRV Z-Score란?',
                        description: '비트코인이 현재 고평가 상태인지 저평가 상태인지 알려주는 온체인 지표입니다.',
                        statusList: [
                          StatusItem(
                            emoji: '🔴',
                            label: '높은 값',
                            value: '시장 과열 (고평가 / 고점 신호)',
                            valueColor: Colors.redAccent,
                          ),
                          StatusItem(
                            emoji: '🟢',
                            label: '낮음/음수',
                            value: '시장 냉각 (저평가 / 저점 신호)',
                            valueColor: Colors.green,
                          ),
                        ],
                        footerNote: '* 현재 시가총액과 실현 시가총액(전체 보유자의 평균 매수 가치)의 차이를 계산한 수치입니다.',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              IconButton(
                tooltip: '차트 확대',
                constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.fullscreen_rounded, size: 22),
                color: const Color(0xFF667085),
                onPressed: expandableHistory == null
                    ? null
                    : () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            fullscreenDialog: true,
                            builder: (_) => MvrvFullscreenScreen(history: expandableHistory),
                          ),
                        );
                      },
              ),
            ],
          ),

          historyAsync.when(
            skipLoadingOnRefresh: false,
            data: (history) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MvrvHistoryChart(history: history),
                  const SizedBox(height: 12),
                  const Text(
                    '차트 데이터: Kote Charts',
                    style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
                  ),
                  if (history.source.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '제공처의 출처 표기: ${history.source}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
                    ),
                  ],
                ],
              );
            },
            loading: () {
              return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
            },
            error: (error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MVRV 차트 데이터를 불러오지 못했습니다.'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(mvrvHistoryProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class IndicatorInfoIconButton extends StatelessWidget {
  final String title;
  final String description;
  final List<StatusItem> statusList;
  final String footerNote;

  const IndicatorInfoIconButton({
    super.key,
    required this.title,
    required this.description,
    required this.statusList,
    required this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.only(left: 4),
      icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: statusList
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item.emoji} ', style: const TextStyle(fontSize: 12)),
                                  Text(
                                    '${item.label}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: item.valueColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(footerNote, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
          ),
        );
      },
    );
  }
}

// 상태 아이템용 데이터 모델
class StatusItem {
  final String emoji;
  final String label;
  final String value;
  final Color valueColor;

  StatusItem({
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
  });
}
