import 'package:btc_horizon/models/mvrv_history_view.dart';
import 'package:intl/intl.dart';
import 'package:btc_horizon/providers/mvrv_history_provider.dart';
import 'package:btc_horizon/screens/mvrv_fullscreen_screen.dart';
import 'package:btc_horizon/widgets/mvrv_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MvrvHistorySection extends ConsumerWidget {
  const MvrvHistorySection({super.key});

  Widget _buildDataStatus(MvrvHistoryView view) {
    final warning = view.verificationFailed || view.persistenceFailed;
    final message = view.isChecking
        ? '이전 차트를 표시하며 서버 자료를 확인하고 있습니다.'
        : view.verificationFailed
        ? '최신 자료를 확인하지 못해 이전 차트를 표시합니다.'
        : '서버 자료를 확인했습니다.';
    final verifiedAt = DateFormat(
      'yyyy.MM.dd HH:mm',
    ).format(view.snapshot.lastVerifiedAt.toLocal());
    final referenceDate = DateFormat(
      'yyyy.MM.dd',
    ).format(view.snapshot.history.points.last.date.toUtc());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFFAEB) : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (view.isChecking) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: warning ? const Color(0xFF93370D) : const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '기록 마지막 날짜 $referenceDate (UTC)\n'
            '차트 서버 확인 $verifiedAt · 기기 시간',
            style: const TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF667085)),
          ),
          if (view.persistenceFailed) ...[
            const SizedBox(height: 6),
            const Text(
              '이번 자료를 기기에 저장하지 못했습니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF93370D)),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(mvrvHistoryProvider);

    final view = historyAsync.asData?.value;
    final expandableHistory = view?.snapshot.history;
    final checking = historyAsync.isLoading || (view?.isChecking ?? false);

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
                        'MVRV Z-Score',
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
                tooltip: '차트 자료 다시 확인',
                onPressed: checking ? null : () => ref.invalidate(mvrvHistoryProvider),
                icon: const Icon(Icons.refresh_rounded, size: 22),
                color: const Color(0xFF667085),
              ),

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
            skipLoadingOnRefresh: true,
            skipError: false,
            data: (view) {
              final history = view.snapshot.history;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataStatus(view),
                  MvrvHistoryChart(history: history),
                  const SizedBox(height: 14),
                  const Text(
                    'Data provider: Kote Charts',
                    style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
                  ),
                  if (history.source.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Source details: ${history.source}',
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
