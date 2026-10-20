import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _accent = Color(0xFF6656B8);
const _grid = Color(0xFFEAECF0);
const _surface = Color(0xFFF8F9FC);
const _warning = Color(0xFF97601F);

final _rankingProvider = StreamProvider.autoDispose<_RankingData>((ref) {
  return FirebaseFirestore.instance
      .collection('app_rank_latest')
      .doc('kr_google_play_top_free')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        final data = snapshot.data();

        if (data == null) {
          throw StateError('앱 순위 문서가 없습니다.');
        }

        if (data['country'] != 'KR' ||
            data['store'] != 'google_play' ||
            data['chart'] != 'top_free' ||
            data['category'] != 'APPLICATION') {
          throw StateError('앱 순위의 조회 조건이 일치하지 않습니다.');
        }

        return _RankingData(data, fromCache: snapshot.metadata.isFromCache);
      });
}, retry: (_, _) => null);

int? _positiveInt(Object? value) {
  if (value is! num || !value.isFinite || value <= 0 || value % 1 != 0) {
    return null;
  }

  return value.toInt();
}

class _RankingData {
  const _RankingData(this.fields, {required this.fromCache});

  final Map<String, dynamic> fields;
  final bool fromCache;

  int? get count => _positiveInt(fields['fetchedCount']);

  bool get isDemo => fields['isDemo'] == true;

  DateTime? get collectedAt {
    final value = fields['collectedAt'];

    return value is Timestamp ? value.toDate().toLocal() : null;
  }

  int? rank(String key) {
    if (fields['${key}Status'] != 'ranked') {
      return null;
    }

    final value = _positiveInt(fields['${key}Rank']);
    final fetchedCount = count;

    if (value == null || fetchedCount == null || value > fetchedCount) {
      return null;
    }

    return value;
  }

  String rankLabel(String key) {
    final value = rank(key);

    if (value != null) {
      return '$value위';
    }

    if (fields['${key}Status'] == 'not_in_fetched_list' &&
        fields['${key}Rank'] == null &&
        count != null) {
      return '목록 밖';
    }

    return '확인 불가';
  }
}

class ExchangeAppInterestCard extends ConsumerStatefulWidget {
  const ExchangeAppInterestCard({super.key});

  @override
  ConsumerState<ExchangeAppInterestCard> createState() => _ExchangeAppInterestCardState();
}

class _ExchangeAppInterestCardState extends ConsumerState<ExchangeAppInterestCard>
    with WidgetsBindingObserver {
  // 하루 한 번 수집하는 운영을 고려한 지연 표시 기준.
  static const _staleAfter = Duration(hours: 48);

  late final Timer _clock;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // 화면의 시간 경과 상태만 갱신합니다.
    // Firestore를 주기적으로 다시 조회하지 않습니다.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _clock.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(_rankingProvider);
  }

  void _showInfo(_RankingData? data) {
    final count = data?.count;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('거래소 앱 관심도'),
        content: SingleChildScrollView(
          child: Text(
            '한국 Google Play의 무료 인기 일반 앱 순위를 통해 '
            '업비트와 빗썸에 대한 관심도를 참고할 수 있습니다. '
            '금융 카테고리만의 순위는 아닙니다.\n\n'
            '${count == null ? '' : '조회 범위: $count개 앱\n'}'
            '“목록 밖”은 조회한 목록에 해당 앱이 없다는 뜻이며, '
            '정확한 순위는 확인할 수 없습니다.\n\n'
            'Google Play의 공개 순위 정보를 주기적으로 수집해 표시합니다. '
            '표시된 수집 시각은 기기의 현지 시간 기준이며, '
            '현재 스토어 순위와 차이가 있을 수 있습니다.\n\n'
            '앱 순위는 시장 관심도의 참고 정보이며, '
            '심리/레버리지 점수에는 반영하지 않습니다.',
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(_rankingProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '거래소 앱 관심도',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
                ),
              ),
              IconButton(
                tooltip: '앱 순위와 조회 기준 안내',
                onPressed: () => _showInfo(rankingAsync.asData?.value),
                icon: const Icon(Icons.info_outline_rounded, size: 20, color: _muted),
              ),
            ],
          ),
          const Text('한국 Google Play · 무료 인기 앱', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 18),
          rankingAsync.when(
            skipLoadingOnRefresh: false,
            loading: _buildLoading,
            error: (error, stackTrace) => _buildError(),
            data: _buildContent,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
            ),
          ),
          const SizedBox(height: 12),
          const Text('저장된 순위를 확인하고 있어요.', style: TextStyle(color: _muted)),
          TextButton(onPressed: _refresh, child: const Text('다시 연결')),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('앱 순위를 불러오지 못했어요.', style: TextStyle(color: _ink)),
        const SizedBox(height: 6),
        const Text('연결 상태를 확인한 뒤 다시 시도해 주세요.', style: TextStyle(fontSize: 13, color: _muted)),
        TextButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('다시 확인'),
          style: TextButton.styleFrom(foregroundColor: _accent),
        ),
      ],
    );
  }

  Widget _buildContent(_RankingData data) {
    final date = data.collectedAt;
    final age = date == null ? null : DateTime.now().difference(date);

    final stale = age != null && age >= _staleAfter;
    final future = age != null && age < const Duration(minutes: -5);

    final String? notice;

    if (data.isDemo) {
      notice = '학습용 모의 데이터 · 실제 순위 아님';
    } else if (future) {
      notice = '수집 시각 확인 필요';
    } else if (stale) {
      notice = '갱신 지연 · 마지막 수집 결과';
    } else {
      notice = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notice != null) ...[_buildNotice(notice, _warning), const SizedBox(height: 12)],
        if (data.fromCache) ...[
          _buildNotice('기기에 저장된 결과 · 서버 연결 확인 중', _muted),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _buildRankRow(
                name: '업비트',
                value: data.rankLabel('upbit'),
                ranked: data.rank('upbit') != null,
              ),
              const Divider(height: 1, color: _grid),
              _buildRankRow(
                name: '빗썸',
                value: data.rankLabel('bithumb'),
                ranked: data.rank('bithumb') != null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.count == null ? '조회 범위 확인 불가' : '조회한 ${data.count}개 앱 목록 기준',
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: _grid),
        const SizedBox(height: 10),
        Text(
          date == null
              ? '수집 시각 확인 불가'
              : '수집 ${DateFormat('yyyy.MM.dd HH:mm').format(date)} · 기기 시간',
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('출처: Google Play', style: TextStyle(fontSize: 12, color: _muted)),
            TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('다시 확인'),
              style: TextButton.styleFrom(foregroundColor: _accent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotice(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, height: 1.5),
    );
  }

  Widget _buildRankRow({required String name, required String value, required bool ranked}) {
    final nameWidget = Text(
      name,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink),
    );

    final valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: ranked ? 22 : 15,
        fontWeight: FontWeight.w700,
        color: ranked ? _accent : _muted,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;

          if (constraints.maxWidth < 220 * scale) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [nameWidget, const SizedBox(height: 6), valueWidget],
            );
          }

          return Row(
            children: [
              Expanded(child: nameWidget),
              const SizedBox(width: 12),
              valueWidget,
            ],
          );
        },
      ),
    );
  }
}
