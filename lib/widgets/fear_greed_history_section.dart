import 'dart:math' as math;
import 'package:btc_horizon/widgets/chart_range_selector.dart';
import 'package:btc_horizon/models/fear_greed_model.dart';
import 'package:btc_horizon/providers/fear_greed_history_provider.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/utils/fear_greed_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

const _ink = Color(0xFF172033);
const _muted = Color(0xFF667085);
const _grid = Color(0xFFEAECF0);
const _line = Color(0xFF6656B8);
const _colors = [
  Color(0xFF5377B6),
  Color(0xFF7AAAB8),
  Color(0xFFA3AAB7),
  Color(0xFFD7A04F),
  Color(0xFFC66C45),
];
const _edges = [0.0, 25.0, 45.0, 55.0, 75.0, 100.0];

Color _stateColor(double value) =>
    _colors[value >= 75
        ? 4
        : value >= 55
        ? 3
        : value >= 45
        ? 2
        : value >= 25
        ? 1
        : 0];
String _date(DateTime value) => DateFormat('yyyy/MM/dd').format(fearGreedDay(value));

class FearGreedHistorySection extends ConsumerStatefulWidget {
  const FearGreedHistorySection({super.key});

  @override
  ConsumerState<FearGreedHistorySection> createState() => _FearGreedHistorySectionState();
}

class _FearGreedHistorySectionState extends ConsumerState<FearGreedHistorySection> {
  FearGreedPeriod _period = FearGreedPeriod.year;
  DateTime? _selectedDay;
  FearGreedWindow? _customWindow;

  @override
  Widget build(BuildContext context) {
    final latestAsync = ref.watch(fearGreedProvider);
    final historyAsync = ref.watch(fearGreedHistoryProvider);
    final history = normalizeFearGreedHistory(
      historyAsync.asData?.value ?? const <FearGreedModel>[],
      latest: latestAsync.asData?.value,
    );
    final latest = history.isEmpty ? null : history.last;
    final firstDay = history.isEmpty ? null : fearGreedDay(history.first.timestamp);
    final lastDay = latest == null ? null : fearGreedDay(latest.timestamp);
    final window = firstDay == null || lastDay == null
        ? null
        : _customWindow?.clamp(firstDay, lastDay) ??
              FearGreedWindow(
                _period == FearGreedPeriod.all ? firstDay : fearGreedPeriodStart(lastDay, _period),
                lastDay,
              ).clamp(firstDay, lastDay);
    final visible = window?.select(history) ?? <FearGreedModel>[];
    final totalDays = firstDay == null || lastDay == null ? 0 : lastDay.difference(firstDay).inDays;
    final rangeValues = totalDays <= 0 || window == null
        ? const RangeValues(0, 1)
        : RangeValues(
            window.start.difference(firstDay!).inDays / totalDays,
            window.end.difference(firstDay).inDays / totalDays,
          );
    final overview = <Offset?>[];
    if (totalDays > 0) {
      for (var i = 0; i < history.length; i++) {
        if (i > 0 &&
            fearGreedDay(
                  history[i].timestamp,
                ).difference(fearGreedDay(history[i - 1].timestamp)).inDays >
                1) {
          overview.add(null);
        }
        overview.add(
          Offset(
            fearGreedDay(history[i].timestamp).difference(firstDay!).inDays / totalDays,
            history[i].value / 100,
          ),
        );
      }
    }
    final viewingPast = window != null && lastDay != null && window.end.isBefore(lastDay);
    FearGreedModel? selected;
    for (final value in visible) {
      if (fearGreedDay(value.timestamp) == _selectedDay) selected = value;
    }
    final canReturnToLatest = selected != null || viewingPast;

    final dayChange = fearGreedDayChange(history);
    final weekAverage = fearGreedWeekAverage(history);

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
                  'Fear & Greed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
                ),
              ),
              IconButton(
                tooltip: '공포·탐욕 지수 안내',
                icon: const Icon(Icons.info_outline_rounded, size: 20, color: _muted),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('공포·탐욕 지수'),
                    content: const SingleChildScrollView(
                      child: Text(
                        '0에 가까울수록 공포, 100에 가까울수록 탐욕을 나타냅니다. 높은 값이 좋은 평가나 상승 확률을 뜻하지는 않습니다.\n\n'
                        '앱 표시 구간: 0~24 극단적 공포, 25~44 공포, 45~54 중립, 55~74 탐욕, 75~100 극단적 탐욕. 기존 앱의 상태 구분을 유지합니다.\n\n'
                        '전일 대비는 바로 전날의 기록과 비교합니다. 7일 평균은 최신 기준일을 포함한 7일의 기록이 모두 있을 때 표시합니다.\n\n'
                        '날짜는 제공처의 UTC 날짜를 기준으로 표시합니다. 차트의 끊어진 부분은 기록이 없는 기간입니다.\n\n'
                        'Data provider: Alternative.me',
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Text('비트코인 시장 심리', style: TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 18),
          if (latest != null) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: latest.value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: _ink,
                        ),
                      ),
                      const TextSpan(
                        text: ' / 100',
                        style: TextStyle(fontSize: 15, color: _muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _stateColor(latest.value).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    fearGreedLabel(latest.value),
                    style: TextStyle(
                      color: Color.lerp(_stateColor(latest.value), _ink, .35),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '기준일 · ${_date(latest.timestamp)}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            if (fearGreedDay(DateTime.now()).difference(fearGreedDay(latest.timestamp)).inDays >= 2)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '최신 기준일이 지난 기록입니다.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9A6700)),
                ),
              ),
            const SizedBox(height: 18),
            _SentimentScale(value: latest.value),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Metric(
                    label: '전일 대비',
                    value: dayChange == null
                        ? '—'
                        : '${dayChange > 0 ? '+' : ''}${dayChange.toStringAsFixed(0)}p',
                  ),
                  _Metric(label: '7일 평균', value: weekAverage?.toStringAsFixed(1) ?? '—'),
                ],
              ),
            ),
          ] else if (latestAsync.isLoading || historyAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            const Text('지수를 불러오지 못했습니다.', style: TextStyle(color: _muted)),
          if (latestAsync.hasError)
            _RetryNotice(
              text: '최신 점수 갱신에 실패했습니다.',
              onRetry: () => ref.invalidate(fearGreedProvider),
            ),
          const SizedBox(height: 22),
          const Text(
            '심리 변화',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final period in FearGreedPeriod.values)
                ChoiceChip(
                  label: Text(period.label),
                  selected: _customWindow == null && _period == period,
                  showCheckmark: false,
                  selectedColor: const Color(0xFFEEEAF9),
                  backgroundColor: const Color(0xFFF7F8FB),
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    color: _customWindow == null && _period == period ? _line : _muted,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() {
                    _period = period;
                    _customWindow = null;
                    _selectedDay = null;
                  }),
                ),
            ],
          ),
          if (historyAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (historyAsync.hasError)
            _RetryNotice(
              text: '과거 기록을 불러오지 못했습니다.',
              onRetry: () => ref.invalidate(fearGreedHistoryProvider),
            )
          else if (history.isNotEmpty && window != null) ...[
            if (visible.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selected != null
                              ? '선택'
                              : viewingPast
                              ? '구간 마지막'
                              : '최신'} · ${_date((selected ?? visible.last).timestamp)}',
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                        Text(
                          '${(selected ?? visible.last).value.toStringAsFixed(0)} · ${fearGreedLabel((selected ?? visible.last).value)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: canReturnToLatest,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Tooltip(
                      message: '최신으로',
                      child: TextButton.icon(
                        onPressed: !canReturnToLatest
                            ? null
                            : () => setState(() {
                                _selectedDay = null;

                                if (viewingPast) {
                                  _customWindow = FearGreedWindow(
                                    lastDay.subtract(window.end.difference(window.start)),
                                    lastDay,
                                  ).clamp(firstDay!, lastDay);
                                }
                              }),
                        style: TextButton.styleFrom(
                          foregroundColor: _line,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('최신으로'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FearGreedHistoryChart(
                values: visible,
                firstDate: window.start,
                lastDate: window.end,
                selectedDay: selected == null ? null : _selectedDay,
                onSelected: (value) => setState(() => _selectedDay = fearGreedDay(value.timestamp)),
              ),
            ] else
              const SizedBox(
                height: 214,
                child: Center(
                  child: Text('선택한 기간에 기록이 없습니다.', style: TextStyle(color: _muted)),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '표시 기간 · ${_date(window.start)} ~ ${_date(window.end)}',
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
            if (totalDays > 0) ...[
              const SizedBox(height: 10),
              ChartRangeSelector(
                key: const ValueKey('fear-greed-range-selector'),
                overviewPoints: overview,
                values: rangeValues,
                minimumSpan: math.min(7, totalDays) / totalDays,
                firstDate: firstDay!,
                lastDate: lastDay!,
                height: 64,
                onChanged: (values) => setState(() {
                  _customWindow = FearGreedWindow.fromFractions(
                    firstDay,
                    lastDay,
                    values.start,
                    values.end,
                  );
                  _selectedDay = null;
                }),
              ),
            ],
            const SizedBox(height: 6),
            const Text('손잡이로 기간 조절 · 선택 영역을 밀어 이동', style: TextStyle(fontSize: 11, color: _muted)),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1, color: _grid),
          const SizedBox(height: 12),
          const Text('점수가 높을수록 탐욕 · 낮을수록 공포', style: TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 5),
          const Text(
            'Data provider: Alternative.me',
            style: TextStyle(fontSize: 12, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
      ),
    ],
  );
}

class _RetryNotice extends StatelessWidget {
  const _RetryNotice({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(text, style: const TextStyle(fontSize: 12, color: _muted)),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

class _SentimentScale extends StatelessWidget {
  const _SentimentScale({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '공포·탐욕 지수 ${value.toStringAsFixed(0)}, ${fearGreedLabel(value)}',
    child: Column(
      children: [
        SizedBox(
          height: 26,
          child: LayoutBuilder(
            builder: (context, box) {
              final x = (value / 100 * box.maxWidth).clamp(5.0, math.max(5.0, box.maxWidth - 5));
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Expanded(
                              flex: (_edges[i + 1] - _edges[i]).round(),
                              child: Container(height: 10, color: _colors[i]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: x - 5,
                    top: 4,
                    child: Container(
                      width: 10,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _ink,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 · 공포', style: TextStyle(fontSize: 11, color: _muted)),
            Text('50 · 중립', style: TextStyle(fontSize: 11, color: _muted)),
            Text('탐욕 · 100', style: TextStyle(fontSize: 11, color: _muted)),
          ],
        ),
      ],
    ),
  );
}

class FearGreedHistoryChart extends StatelessWidget {
  const FearGreedHistoryChart({
    super.key,
    required this.values,
    required this.selectedDay,
    required this.onSelected,
    this.firstDate,
    this.lastDate,
  });
  final List<FearGreedModel> values;
  final DateTime? selectedDay;
  final ValueChanged<FearGreedModel> onSelected;
  final DateTime? firstDate, lastDate;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 214 + math.max(0, MediaQuery.textScalerOf(context).scale(11) - 11) * 2,
    child: LayoutBuilder(
      builder: (context, box) {
        final painter = _HistoryPainter(
          values,
          selectedDay,
          MediaQuery.textScalerOf(context),
          Theme.of(context).textTheme.bodySmall?.fontFamily,
          firstDate,
          lastDate,
        );
        void select(Offset position) {
          if (values.isEmpty) return;
          final plot = painter.plot(Size(box.maxWidth, box.maxHeight));
          if (!plot.contains(position)) return;
          final start = fearGreedDay(firstDate ?? values.first.timestamp).millisecondsSinceEpoch;
          final end = fearGreedDay(lastDate ?? values.last.timestamp).millisecondsSinceEpoch;
          final target = start + ((position.dx - plot.left) / plot.width) * (end - start);
          var closest = values.first;
          for (final value in values) {
            if ((fearGreedDay(value.timestamp).millisecondsSinceEpoch - target).abs() <
                (fearGreedDay(closest.timestamp).millisecondsSinceEpoch - target).abs()) {
              closest = value;
            }
          }
          onSelected(closest);
        }

        return Semantics(
          label: '공포·탐욕 지수 추이, 세로축 0부터 100',
          child: GestureDetector(
            key: const ValueKey('fear-greed-history-chart'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => select(details.localPosition),
            onLongPressStart: (details) => select(details.localPosition),
            onLongPressMoveUpdate: (details) => select(details.localPosition),
            child: CustomPaint(painter: painter, size: Size.infinite),
          ),
        );
      },
    ),
  );
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(
    this.values,
    this.selectedDay,
    this.textScaler,
    this.fontFamily,
    this.firstDate,
    this.lastDate,
  );
  final List<FearGreedModel> values;
  final DateTime? selectedDay;
  final TextScaler textScaler;
  final String? fontFamily;
  final DateTime? firstDate, lastDate;

  Rect plot(Size size) => Rect.fromLTRB(
    2,
    10,
    math.max(3, size.width - textScaler.scale(11) * 2.4 - 12),
    size.height - textScaler.scale(11) - 20,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final area = plot(size);
    final start = fearGreedDay(firstDate ?? values.first.timestamp).millisecondsSinceEpoch;
    final end = fearGreedDay(lastDate ?? values.last.timestamp).millisecondsSinceEpoch;
    // 2년을 초과하는 구간은 장기 보기로 처리합니다.
    final isLongRange = end - start > const Duration(days: 730).inMilliseconds;
    double x(FearGreedModel v) => end == start
        ? area.center.dx
        : area.left +
              (fearGreedDay(v.timestamp).millisecondsSinceEpoch - start) /
                  (end - start) *
                  area.width;
    double y(double v) => area.bottom - v / 100 * area.height;
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTRB(area.left, y(_edges[i + 1]), area.right, y(_edges[i])),
        Paint()..color = _colors[i].withValues(alpha: .055),
      );
    }
    for (final tick in [0, 25, 50, 75, 100]) {
      canvas.drawLine(
        Offset(area.left, y(tick.toDouble())),
        Offset(area.right, y(tick.toDouble())),
        Paint()..color = tick == 50 ? const Color(0xFFC8CED9) : _grid,
      );
      _text(canvas, '$tick', Offset(area.right + 7, y(tick.toDouble())), centerY: true);
    }
    canvas.save();
    canvas.clipRect(area.inflate(2));
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final gap =
          i == 0 ||
          fearGreedDay(value.timestamp).difference(fearGreedDay(values[i - 1].timestamp)).inDays >
              1;
      if (gap) {
        path.moveTo(x(value), y(value.value));
      } else {
        path.lineTo(x(value), y(value.value));
      }
      if (gap) canvas.drawCircle(Offset(x(value), y(value.value)), 1.6, Paint()..color = _line);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _line
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLongRange ? 1.1 : 1.6
        ..strokeJoin = StrokeJoin.round,
    );
    final active = values.where((v) => fearGreedDay(v.timestamp) == selectedDay).firstOrNull;
    final dot = active ?? values.last;
    if (active != null) {
      for (var top = area.top; top < area.bottom; top += 6) {
        canvas.drawLine(
          Offset(x(dot), top),
          Offset(x(dot), math.min(top + 3, area.bottom)),
          Paint()..color = const Color(0xFF949CAE),
        );
      }
    }
    canvas.drawCircle(Offset(x(dot), y(dot.value)), 4, Paint()..color = _line);
    canvas.drawCircle(Offset(x(dot), y(dot.value)), 2, Paint()..color = Colors.white);
    canvas.restore();
    final format = DateFormat(
      isLongRange
          ? 'yyyy'
          : end - start > const Duration(days: 180).inMilliseconds
          ? 'yy.MM'
          : 'MM/dd',
    );
    if (end == start) {
      _text(
        canvas,
        format.format(fearGreedDay(values.first.timestamp)),
        Offset(area.center.dx, area.bottom + 10),
        align: .5,
      );
    } else {
      final fractions = area.width > textScaler.scale(11) * 16 ? [0.0, .5, 1.0] : [0.0, 1.0];
      for (final fraction in fractions) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          (start + (end - start) * fraction).round(),
          isUtc: true,
        );
        _text(
          canvas,
          format.format(date),
          Offset(area.left + fraction * area.width, area.bottom + 10),
          align: fraction,
        );
      }
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset position, {
    double align = 0,
    bool centerY = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(fontSize: 11, color: _muted, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    painter.paint(
      canvas,
      Offset(position.dx - painter.width * align, position.dy - (centerY ? painter.height / 2 : 0)),
    );
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) =>
      oldDelegate.firstDate != firstDate ||
      oldDelegate.lastDate != lastDate ||
      oldDelegate.values != values ||
      oldDelegate.selectedDay != selectedDay ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.fontFamily != fontFamily;
}
