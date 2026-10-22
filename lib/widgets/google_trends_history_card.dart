import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:btc_horizon/models/google_trends_history_model.dart';
import 'package:btc_horizon/providers/google_trends_history_provider.dart';
import 'package:btc_horizon/widgets/chart_date_axis.dart';
import 'package:btc_horizon/widgets/chart_range_selector.dart';

const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _line = Color(0xFF208A9A);
const _grid = Color(0xFFEAECF0);

class GoogleTrendsHistoryCard extends ConsumerStatefulWidget {
  const GoogleTrendsHistoryCard({super.key});
  @override
  ConsumerState<GoogleTrendsHistoryCard> createState() => _GoogleTrendsHistoryCardState();
}

class _GoogleTrendsHistoryCardState extends ConsumerState<GoogleTrendsHistoryCard> {
  GoogleTrendsRegion _region = GoogleTrendsRegion.korea;
  RangeValues? _customRange;
  bool _all = false;
  DateTime? _selected;
  bool _refreshing = false;

  Future<void> _refresh() async {
    final region = _region;
    setState(() => _refreshing = true);
    try {
      await FirebaseFirestore.instance
          .doc(region.documentPath)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (mounted) ref.invalidate(googleTrendsHistoryByRegionProvider(region));
    } catch (_) {
      if (mounted && _region == region) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('새 자료를 확인하지 못했습니다. 연결 상태를 확인해 주세요.')));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _info() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('비트코인 검색 관심도'),
      content: SingleChildScrollView(
        child: Text(
          '${_region.label} Google 웹 검색에서 “${_region.query}” 검색어의 상대적 관심도를 보여줍니다. '
          '전체 투자자의 관심도를 뜻하지는 않습니다. 전 세계 자료도 bitcoin이라는 검색어의 자료이며, '
          '모든 언어를 묶은 Bitcoin 주제 자료는 아닙니다.\n\n'
          '한국과 전 세계는 각각 따로 조회한 자료입니다. 각 자료의 100은 각 조회 조건의 최고점이므로, '
          '두 지역의 지수를 검색량의 크기로 직접 비교할 수 없습니다.\n\n'
          '2009년 1월 3일부터 조회 종료일까지 한 번에 받은 월별 데이터입니다. '
          '100은 해당 조회 조건의 최고 관심도이며 검색 횟수나 백분율이 아닙니다. '
          '0은 검색량이 적어 표시되지 않은 경우도 포함합니다.\n\n'
          '기간 버튼과 선택기는 표시 범위만 바꾸며 값을 재계산하지 않습니다. '
          '다시 수집하면 표본이나 최고점 변화로 과거 값도 달라질 수 있습니다.\n\n'
          '현재 월이나 일부만 집계된 월에는 “집계 중”을 표시합니다. '
          '관심도 상승만으로 탐욕이나 상승장을 단정할 수 없으며, 종합 점수에는 반영하지 않습니다.\n\n'
          '“다시 확인”은 저장된 결과를 읽습니다. 출처: Google Trends · 비공식 수집. '
          '월은 제공처의 UTC 기준, 수집 시각은 기기 현지 시간입니다.',
          style: const TextStyle(height: 1.6),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final provider = googleTrendsHistoryByRegionProvider(_region);
    final async = ref.watch(provider);
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
                  '비트코인 검색 관심도',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
                ),
              ),
              IconButton(
                tooltip: '검색 관심도 안내',
                onPressed: _info,
                icon: const Icon(Icons.info_outline_rounded, color: _muted, size: 20),
              ),
            ],
          ),
          const Text('Google 웹 검색 · 월별', style: TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final region in GoogleTrendsRegion.values)
                ChoiceChip(
                  key: ValueKey('trends-region-${region.country}'),
                  label: Text('${region.label} · ${region.query}'),
                  selected: _region == region,
                  showCheckmark: false,
                  selectedColor: const Color(0xFFE5F3F5),
                  backgroundColor: const Color(0xFFF7F8FB),
                  side: BorderSide.none,
                  onSelected: (_) {
                    if (_region == region) return;
                    setState(() {
                      _region = region;
                      _customRange = null;
                      _selected = null;
                      _all = false;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          async.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () =>
                const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_region.label} 검색 관심도를 불러오지 못했습니다.\n데이터 등록 및 연결 상태를 확인해 주세요.',
                  style: const TextStyle(color: _muted, height: 1.6),
                ),
                TextButton(onPressed: () => ref.invalidate(provider), child: const Text('다시 시도')),
              ],
            ),
            data: _content,
          ),
        ],
      ),
    );
  }

  Widget _content(GoogleTrendsHistoryModel data) {
    final points = data.points;
    final last = points.length - 1;

    final firstMs = points.first.month.millisecondsSinceEpoch;
    final spanMs = points.last.month.millisecondsSinceEpoch - firstMs;

    // 실제 날짜 간격을 유지합니다.
    double fraction(int index) => (points[index].month.millisecondsSinceEpoch - firstMs) / spanMs;

    int nearestIndex(double value) {
      var nearest = 0;

      for (var i = 1; i <= last; i++) {
        if ((fraction(i) - value).abs() < (fraction(nearest) - value).abs()) {
          nearest = i;
        }
      }

      return nearest;
    }

    // 월별 데이터 12개 = 월 사이 간격 11개.
    // 데이터가 12개 미만이면 전체 데이터를 표시합니다.
    final minimumIntervals = math.min(11, last);

    // 모든 12개 월 구간 중 실제 날짜 폭이 가장 짧은 값을 구합니다.
    // 월마다 일수가 달라도 유효한 선택 범위를 막지 않도록 합니다.
    var minimumSpan = 1.0;

    for (var i = 0; i + minimumIntervals <= last; i++) {
      final actualSpan = fraction(i + minimumIntervals) - fraction(i);

      minimumSpan = math.min(minimumSpan, actualSpan);
    }

    final since = points.indexWhere((point) => point.month.year >= 2017);

    final defaultStart = _all || since < 0 ? 0 : math.min(since, last - minimumIntervals);

    // 가까운 월로 맞춘 뒤에도 최소 월 개수를 보장합니다.
    final start = (_customRange == null ? defaultStart : nearestIndex(_customRange!.start))
        .clamp(0, last - minimumIntervals)
        .toInt();

    final end = (_customRange == null ? last : nearestIndex(_customRange!.end))
        .clamp(start + minimumIntervals, last)
        .toInt();

    final visible = points.sublist(start, end + 1);
    final selectedIndex = visible.indexWhere((point) => point.month == _selected);
    final focus = selectedIndex >= 0 ? visible[selectedIndex] : visible.last;
    final monthFormat = DateFormat('yyyy.MM');
    final range = RangeValues(fraction(start), fraction(end));
    final overview = [
      for (var i = 0; i < points.length; i++) Offset(fraction(i), points[i].value / 100),
    ];
    final age = DateTime.now().difference(data.collectedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final all in [false, true])
              ChoiceChip(
                label: Text(all ? '전체' : '2017년 이후'),
                showCheckmark: false,
                selected: _customRange == null && _all == all,
                selectedColor: const Color(0xFFE5F3F5),
                backgroundColor: const Color(0xFFF7F8FB),
                side: BorderSide.none,
                onSelected: (_) => setState(() {
                  _all = all;
                  _customRange = null;
                  _selected = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${selectedIndex >= 0
              ? '선택'
              : end == last
              ? '최신'
              : '구간 마지막'} · ${monthFormat.format(focus.month)}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${focus.value}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _ink),
            ),
            const Text('/ 100', style: TextStyle(color: _muted)),
            if (data.isProvisional(focus))
              const Text('집계 중', style: TextStyle(color: Color(0xFF97601F), fontSize: 12)),
            if (_selected != null)
              TextButton(
                onPressed: () => setState(() => _selected = null),
                child: const Text('선택 해제'),
              ),
          ],
        ),
        const Text('전체 조회 기간 기준 상대 지수', style: TextStyle(fontSize: 11, color: _muted)),
        const SizedBox(height: 14),
        _MonthlyPlot(
          points: visible,
          selected: _selected,
          data: data,
          onSelected: (month) => setState(() => _selected = month),
        ),
        const SizedBox(height: 8),
        Text(
          '표시 기간 · ${monthFormat.format(visible.first.month)} ~ ${monthFormat.format(visible.last.month)}',
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
        const SizedBox(height: 12),
        if (spanMs > 0)
          ChartRangeSelector(
            overviewPoints: overview,
            values: range,
            minimumSpan: minimumSpan,
            firstDate: points.first.month,
            lastDate: points.last.month,
            onChanged: (value) => setState(() {
              _customRange = value;
              _selected = null;
            }),
          ),
        const SizedBox(height: 8),
        const Text(
          '손잡이로 기간 조절 · 표시 범위를 바꿔도 지수는 유지됩니다.',
          style: TextStyle(fontSize: 11, height: 1.5, color: _muted),
        ),
        const SizedBox(height: 12),
        const Divider(color: _grid),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '수집 ${DateFormat('yyyy.MM.dd HH:mm').format(data.collectedAt.toLocal())}',
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
            if (data.fromCache) const Text('저장된 자료', style: TextStyle(fontSize: 11, color: _muted)),
            if (age.inDays >= 14)
              const Text(
                '수집 후 14일 이상 경과',
                style: TextStyle(fontSize: 11, color: Color(0xFF97601F)),
              ),
            TextButton(
              onPressed: _refreshing ? null : _refresh,
              child: Text(_refreshing ? '확인 중…' : '다시 확인'),
            ),
          ],
        ),
        const Text('출처: Google Trends', style: TextStyle(fontSize: 11, color: _muted)),
      ],
    );
  }
}

class _MonthlyPlot extends StatelessWidget {
  const _MonthlyPlot({
    required this.points,
    required this.selected,
    required this.data,
    required this.onSelected,
  });
  final List<GoogleTrendsPoint> points;
  final DateTime? selected;
  final GoogleTrendsHistoryModel data;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final right = 36.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final width = math.max(1.0, constraints.maxWidth - right);
      final first = points.first.month;
      final span = points.last.month.millisecondsSinceEpoch - first.millisecondsSinceEpoch;
      void select(Offset position) {
        if (position.dx < 0 || position.dx > width) return;
        final time = first.millisecondsSinceEpoch + span * (position.dx / width).clamp(0.0, 1.0);
        final nearest = points.reduce(
          (a, b) =>
              (a.month.millisecondsSinceEpoch - time).abs() <=
                  (b.month.millisecondsSinceEpoch - time).abs()
              ? a
              : b,
        );
        onSelected(nearest.month);
      }

      return Column(
        children: [
          Semantics(
            label: '월별 검색 관심도 차트. 0부터 100. 차트를 눌러 해당 월을 선택합니다.',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (event) => select(event.localPosition),
              onHorizontalDragUpdate: (event) => select(event.localPosition),
              child: SizedBox(
                height: 242,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MonthlyPainter(
                    points,
                    selected,
                    data,
                    right,
                    MediaQuery.textScalerOf(context),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: right),
            child: ChartDateAxis(
              firstDate: first,
              startDay: 0,
              endDay: points.last.month.difference(first).inDays,
            ),
          ),
        ],
      );
    },
  );
}

class _MonthlyPainter extends CustomPainter {
  _MonthlyPainter(this.points, this.selected, this.data, this.right, this.scaler);
  final List<GoogleTrendsPoint> points;
  final DateTime? selected;
  final GoogleTrendsHistoryModel data;
  final double right;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0, 8, math.max(1, size.width - right), size.height - 8);
    final first = points.first.month.millisecondsSinceEpoch;
    final span = points.last.month.millisecondsSinceEpoch - first;
    Offset position(GoogleTrendsPoint point) => Offset(
      (point.month.millisecondsSinceEpoch - first) / span * rect.width,
      rect.bottom - point.value / 100 * rect.height,
    );
    for (final value in [0, 25, 50, 75, 100]) {
      final y = rect.bottom - value / 100 * rect.height;
      canvas.drawLine(Offset(0, y), Offset(rect.right, y), Paint()..color = _grid);
      final label = TextPainter(
        text: TextSpan(
          text: '$value',
          style: const TextStyle(fontSize: 10, color: _muted),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      label.paint(canvas, Offset(rect.right + 7, y - label.height / 2));
      label.dispose();
    }
    canvas.save();
    canvas.clipRect(rect.inflate(3));
    final area = Path()..moveTo(0, rect.bottom);
    for (final point in points) {
      final p = position(point);
      area.lineTo(p.dx, p.dy);
    }
    area.lineTo(rect.right, rect.bottom);
    area.close();
    canvas.drawPath(area, Paint()..color = _line.withValues(alpha: .06));
    for (var i = 1; i < points.length; i++) {
      final a = position(points[i - 1]);
      final b = position(points[i]);
      final paint = Paint()
        ..color = _line
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      if (data.isProvisional(points[i]) || data.isProvisional(points[i - 1])) {
        final length = (b - a).distance;
        for (var d = 0.0; d < length; d += 8) {
          canvas.drawLine(
            Offset.lerp(a, b, d / length)!,
            Offset.lerp(a, b, math.min(1, (d + 4) / length))!,
            paint,
          );
        }
      } else {
        canvas.drawLine(a, b, paint);
      }
    }
    for (final point in points.where((point) => point.month == selected)) {
      final p = position(point);
      for (var y = rect.top; y < rect.bottom; y += 7) {
        canvas.drawLine(
          Offset(p.dx, y),
          Offset(p.dx, math.min(y + 3, rect.bottom)),
          Paint()..color = _muted,
        );
      }
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3, Paint()..color = _line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MonthlyPainter old) => true;
}
