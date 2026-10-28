import 'package:btc_horizon/models/mvrv_latest_model.dart';
import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:btc_horizon/utils/mvrv_freshness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// MVRV 지표 행 아래에서 부가 정보와 최신 자료 재조회를 제공합니다.
class MvrvDataInfo extends ConsumerStatefulWidget {
  const MvrvDataInfo({super.key});

  @override
  ConsumerState<MvrvDataInfo> createState() => _MvrvDataInfoState();
}

class _MvrvDataInfoState extends ConsumerState<MvrvDataInfo> {
  bool _expanded = false;

  String _formatDay(DateTime value) => DateFormat('yyyy.MM.dd').format(value.toUtc());

  String _formatTime(DateTime value) => DateFormat('yyyy.MM.dd HH:mm').format(value.toLocal());

  Widget _notice({required String title, required String message}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFEDFA0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB54708)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF93370D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF93370D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _freshnessNotice(MvrvLatestModel data) {
    final freshness = evaluateMvrvFreshness(data);

    // 날짜·시각이 맞지 않으면 지연 여부보다 먼저 안내합니다.
    if (freshness.needsClockCheck) {
      return _notice(
        title: '날짜·시각 확인 필요',
        message:
            '마지막 확인 당시 데이터 날짜 또는 서버 저장 시각이 '
            '앱의 확인 시각보다 미래로 표시되었습니다.\n'
            '기기의 날짜·시간 설정을 확인한 뒤 다시 조회해 주세요. '
            '문제가 계속되면 데이터 시각도 확인해야 합니다.',
      );
    }

    final messages = <String>[];

    if (freshness.isSourceDateOld) {
      messages.add(
        '점수 기준일이 확인 날짜보다 '
        '${freshness.sourceLagDays}일 이전입니다.',
      );
    }

    if (freshness.isCollectionOld) {
      messages.add(
        '서버에 자료가 저장된 지 '
        '${freshness.collectionAge.inHours}시간 이상 지났습니다.',
      );
    }

    // 기준을 넘지 않았다면 별도 안내를 표시하지 않습니다.
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return _notice(
      title: '데이터 갱신 확인 필요',
      message:
          '마지막 확인 당시:\n'
          '${messages.join('\n')}\n\n'
          '표시된 기준일의 값으로 점수를 계산하고 있습니다.',
    );
  }

  Widget _details(MvrvLatestModel data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 점수는 ${_formatDay(data.latestConfirmed.date)} '
            '기준 데이터로 계산했습니다.',
            style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF475467)),
          ),
          const SizedBox(height: 12),

          Text(
            '데이터 수집 시각  ${_formatTime(data.collectedAt)}\n'
            '마지막 확인 시각  ${_formatTime(data.checkedAt)}',
            style: const TextStyle(fontSize: 13, height: 1.8, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 10),

          const Text(
            '수집 시각은 서버에 자료를 저장한 시간이며,\n'
            '마지막 확인은 앱에서 해당 자료를 조회한 시간입니다.',
            style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 6),

          const Text(
            '점수 기준일은 UTC 날짜 기준입니다.\n'
            '수집·확인 시각은 기기 현지 시간으로 표시합니다.',
            style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestAsync = ref.watch(mvrvLatestProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  expanded: _expanded,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF667085),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(48, 48),
                    ),
                    icon: Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20,
                    ),
                    label: const Text('데이터 정보'),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'MVRV 최신 자료 다시 확인',
              onPressed: latestAsync.isLoading ? null : () => ref.invalidate(mvrvLatestProvider),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: const Color(0xFF667085),
            ),
          ],
        ),
        // 로딩·실패 안내는 정보가 접혀 있어도 표시합니다.
        latestAsync.when(
          skipLoadingOnRefresh: false,
          skipError: false,
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MVRV 자료를 확인하고 있습니다.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                  ),
                ),
              ],
            ),
          ),
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'MVRV 자료를 확인하지 못했습니다.\n'
              '잠시 후 다시 확인 버튼을 눌러 주세요.',
              style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFFB54708)),
            ),
          ),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 주의 안내는 데이터 정보가 접혀 있어도 표시합니다.
              _freshnessNotice(data),

              // 자세한 날짜 설명은 펼쳤을 때만 표시합니다.
              if (_expanded) _details(data),
            ],
          ),
        ),
      ],
    );
  }
}
