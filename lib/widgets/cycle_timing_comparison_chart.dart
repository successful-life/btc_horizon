import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:btc_horizon/models/cycle_timing_comparison_model.dart';
import 'package:btc_horizon/widgets/chart_date_axis.dart';
import 'package:btc_horizon/widgets/chart_range_selector.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_legend.dart';
import 'package:btc_horizon/widgets/cycle_timing_comparison_style.dart';

/// 날짜를 사용하므로 데이터가 새로 들어와도 선택한 과거 구간을 유지합니다.
/// startDate/endDate가 null이면 전체 기록을 표시합니다.
class CycleTimingComparisonChartView {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? selectedDate;

  const CycleTimingComparisonChartView({this.startDate, this.endDate, this.selectedDate});
}

class CycleTimingComparisonChart extends StatefulWidget {
  final CycleTimingComparisonModel comparison;
  final bool fillAvailableSpace;
  final CycleTimingComparisonChartView? initialView;
  final ValueChanged<CycleTimingComparisonChartView>? onViewChanged;
  final VoidCallback? onExpand;

  const CycleTimingComparisonChart({
    super.key,
    required this.comparison,
    this.fillAvailableSpace = false,
    this.initialView,
    this.onViewChanged,
    this.onExpand,
  });

  @override
  State<CycleTimingComparisonChart> createState() => _CycleTimingComparisonChartState();
}

class _CycleTimingComparisonChartState extends State<CycleTimingComparisonChart> {
  static const _rightPadding = 8.0;
  static final _dateFormat = DateFormat('yyyy/MM/dd');
  static final _priceFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  DateTime _firstDate = DateTime.utc(2000);
  List<FlSpot> _spots = [];
  List<Offset?> _overview = [];
  List<int> _days = [];
  Map<int, double> _prices = {};
  Map<int, double> _logs = {};
  int _fullEnd = 1;
  int _startDay = 0;
  int _endDay = 1;
  int? _selectedDay;
  double _minY = 0;
  double _maxY = 1;
  bool _draggingRange = false;

  bool get _hasData => _days.isNotEmpty;
  bool get _isFullRange => _startDay == 0 && _endDay == _fullEnd;
  int get _minimumSpan => math.min(30, _fullEnd);
  int _day(DateTime date) => chartCalendarDayKey(date) - chartCalendarDayKey(_firstDate);
  DateTime _date(int day) => _firstDate.add(Duration(days: day));

  CycleTimingComparisonChartView get _view => CycleTimingComparisonChartView(
    startDate: _isFullRange ? null : _date(_startDay),
    endDate: _isFullRange ? null : _date(_endDay),
    selectedDate: _selectedDay == null ? null : _date(_selectedDay!),
  );

  @override
  void initState() {
    super.initState();
    _prepare(widget.initialView ?? const CycleTimingComparisonChartView());
  }

  @override
  void didUpdateWidget(covariant CycleTimingComparisonChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.comparison, widget.comparison)) {
      _prepare(_view, followRightEdge: _endDay == _fullEnd);
    }
  }

  void _prepare(CycleTimingComparisonChartView view, {bool followRightEdge = false}) {
    final points =
        widget.comparison.chartPoints
            .where((point) => point.closePrice.isFinite && point.closePrice > 0)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    _spots = [];
    _overview = [];
    _days = [];
    _prices = {};
    _logs = {};
    _selectedDay = null;
    if (points.isEmpty) {
      return;
    }

    _firstDate = DateTime.utc(
      points.first.date.year,
      points.first.date.month,
      points.first.date.day,
    );
    for (final point in points) {
      final day = _day(point.date);
      _prices[day] = point.closePrice;
      _logs[day] = math.log(point.closePrice) / math.ln10;
    }
    _days = _prices.keys.toList()..sort();
    // 분석 기준일 뒤의 여백은 날짜만 표시합니다. 미래 종가를 만들지 않습니다.
    _fullEnd = math.max(_days.last, _day(widget.comparison.asOfDate)) + 30;
    final low = _logs.values.reduce(math.min);
    final high = _logs.values.reduce(math.max);
    final overviewSpan = math.max(high - low, .02);
    final overviewMin = (low + high) / 2 - overviewSpan * .6;
    final overviewMax = (low + high) / 2 + overviewSpan * .6;
    if (!_draggingRange) {
      _minY = overviewMin;
      _maxY = overviewMax;
    }

    // 보통의 표시 간격보다 큰 데이터 공백은 선으로 잇지 않습니다.
    // provider가 1일/3일 등으로 샘플링해도 마지막 캔들 때문에 간격이 오인되지 않습니다.
    final counts = <int, int>{};
    for (var i = 1; i < _days.length; i++) {
      final gap = _days[i] - _days[i - 1];
      counts[gap] = (counts[gap] ?? 0) + 1;
    }
    var step = 1;
    var count = 0;
    for (final entry in counts.entries) {
      if (entry.value > count || (entry.value == count && entry.key < step)) {
        step = entry.key;
        count = entry.value;
      }
    }
    int? previous;
    for (final day in _days) {
      if (previous != null && day - previous > step) {
        _spots.add(FlSpot.nullSpot);
        _overview.add(null);
      }
      final logPrice = _logs[day]!;
      _spots.add(FlSpot(day.toDouble(), logPrice));
      _overview.add(Offset(day / _fullEnd, (logPrice - overviewMin) / (overviewMax - overviewMin)));
      previous = day;
    }

    if (view.startDate == null || view.endDate == null) {
      _startDay = 0;
      _endDay = _fullEnd;
    } else {
      final span = (chartCalendarDayKey(view.endDate!) - chartCalendarDayKey(view.startDate!))
          .clamp(_minimumSpan, _fullEnd);
      _startDay = followRightEdge
          ? _fullEnd - span
          : _day(view.startDate!).clamp(0, _fullEnd - span);
      _endDay = _startDay + span;
    }
    if (view.selectedDate != null) {
      final day = _day(view.selectedDate!);
      if (day >= _startDay && day <= _endDay) {
        _selectedDay = day;
      }
    }
    if (!_draggingRange) {
      _fitVisibleY();
    }
  }

  int _lowerBound(int day) {
    var low = 0;
    var high = _days.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (_days[middle] < day) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int? get _displayDay {
    if (_selectedDay != null) {
      return _selectedDay;
    }
    final index = _lowerBound(_endDay + 1) - 1;
    return index >= 0 && _days[index] >= _startDay ? _days[index] : null;
  }

  void _reportView() => widget.onViewChanged?.call(_view);

  void _fitVisibleY() {
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (var i = _lowerBound(_startDay); i < _days.length && _days[i] <= _endDay; i++) {
      final value = _logs[_days[i]]!;
      low = math.min(low, value);
      high = math.max(high, value);
    }
    // 미래/누락 구간에서는 마지막 유효 축을 유지합니다.
    if (!low.isFinite || !high.isFinite) {
      return;
    }
    final span = math.max(high - low, .02);
    final middle = (low + high) / 2;
    _minY = middle - span * .6;
    _maxY = middle + span * .6;
  }

  void _changeRange(RangeValues range) {
    final start = (range.start * _fullEnd).round().clamp(0, _fullEnd - _minimumSpan);
    final end = (range.end * _fullEnd).round().clamp(start + _minimumSpan, _fullEnd);
    if (start == _startDay && end == _endDay) {
      return;
    }
    setState(() {
      _startDay = start;
      _endDay = end;
      if (_selectedDay != null && (_selectedDay! < start || _selectedDay! > end)) {
        _selectedDay = null;
      }
      if (!_draggingRange) {
        _fitVisibleY();
      }
    });
    _reportView();
  }

  void _endRangeDrag() {
    if (!_draggingRange) {
      return;
    }
    setState(() {
      _draggingRange = false;
      _fitVisibleY();
    });
  }

  void _selectDate(double x) {
    final day = x.round().clamp(_startDay, _endDay);
    if (day == _selectedDay) {
      return;
    }
    setState(() => _selectedDay = day);
    _reportView();
  }

  void _goToLatest() {
    final last = _days.last;
    final span = _endDay - _startDay;
    setState(() {
      if (last < _startDay || last > _endDay) {
        _endDay = math.min(_fullEnd, last + span ~/ 5).clamp(span, _fullEnd);
        _startDay = _endDay - span;
      }
      _selectedDay = last;
      _fitVisibleY();
    });
    _reportView();
  }

  Widget _quote() {
    final day = _displayDay;
    final price = day == null ? null : _prices[day];
    final label = _selectedDay != null
        ? '선택 날짜'
        : day == _days.last
        ? '최근 종가'
        : '기간 내 마지막';
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day == null ? '선택 기간에 종가가 없습니다.' : '$label · ${_dateFormat.format(_date(day))}',
            style: const TextStyle(fontSize: 11, color: CycleTimingComparisonStyle.muted),
          ),
          const SizedBox(height: 2),
          Text(
            price == null ? '가격 데이터 없음' : _priceFormat.format(price),
            style: TextStyle(
              fontSize: price == null
                  ? 12
                  : widget.fillAvailableSpace
                  ? 16
                  : 20,
              color: price == null
                  ? CycleTimingComparisonStyle.muted
                  : CycleTimingComparisonStyle.price,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _latestButton() => TextButton(
    onPressed: _displayDay == _days.last ? null : _goToLatest,
    style: TextButton.styleFrom(
      foregroundColor: CycleTimingComparisonStyle.price,
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    child: const Text('최근으로'),
  );

  Widget _fullRangeButton() => Semantics(
    selected: _isFullRange,
    child: TextButton(
      onPressed: () => _changeRange(const RangeValues(0, 1)),
      style: TextButton.styleFrom(
        foregroundColor: _isFullRange
            ? CycleTimingComparisonStyle.price
            : CycleTimingComparisonStyle.muted,
        backgroundColor: _isFullRange ? const Color(0xFFEAF6FA) : const Color(0xFFF7F9FC),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: const Text('전체 기간'),
    ),
  );

  Widget _normalToolbar() => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
      final stack = constraints.maxWidth < 300 || scale > 1.4;
      final chartControls = Row(
        children: [
          if (!stack) ...[_fullRangeButton(), const SizedBox(width: 12)],
          const Expanded(
            child: Text(
              'BTC/USD · 로그 축',
              style: TextStyle(fontSize: 11, color: CycleTimingComparisonStyle.price),
            ),
          ),
          if (widget.onExpand != null)
            IconButton(
              tooltip: '차트 확대',
              onPressed: widget.onExpand,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              color: CycleTimingComparisonStyle.muted,
              icon: const Icon(Icons.fullscreen_rounded),
            ),
        ],
      );
      if (!stack) {
        return chartControls;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: _fullRangeButton()),
          const SizedBox(height: 4),
          chartControls,
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Text(
          '비교 차트를 표시할 데이터가 부족합니다.',
          style: TextStyle(fontSize: 13, color: CycleTimingComparisonStyle.muted),
        ),
      );
    }

    final compact = widget.fillAvailableSpace;
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final axisWidth = 54.0 * scale;
    bool visible(int day) => day >= _startDay && day <= _endDay;
    // 선택 기간/날짜는 계산 입력이 아닙니다. provider가 준 기준일과 진행률을 그대로 사용합니다.
    final halvingDays = <int>{
      for (final item in widget.comparison.comparisons) ...[
        _day(item.cycle.startDate),
        _day(item.cycle.endDate),
      ],
      _day(widget.comparison.currentCycle.startDate),
    }.where(visible).toList()..sort();
    final progressDays = <int>{
      for (final item in widget.comparison.comparisons) _day(item.equivalentDate),
      _day(widget.comparison.asOfDate),
    }.where(visible).toList()..sort();
    final ranges = <VerticalRangeAnnotation>[];
    void addRange(DateTime start, DateTime end, Color color) {
      final left = math.max(_startDay, _day(start)).toDouble();
      final right = math.min(_endDay, _day(end)).toDouble();
      if (right > left) {
        ranges.add(VerticalRangeAnnotation(x1: left, x2: right, color: color));
      }
    }

    for (final item in widget.comparison.comparisons) {
      addRange(item.cycle.startDate, item.equivalentDate, CycleTimingComparisonStyle.pastRange);
    }
    addRange(
      widget.comparison.currentCycle.startDate,
      widget.comparison.asOfDate,
      CycleTimingComparisonStyle.currentRange,
    );
    final index = _lowerBound(_startDay);
    final showPrice = index < _days.length && _days[index] <= _endDay;

    final chart = _buildPriceChart(axisWidth, halvingDays, progressDays, ranges);
    return Column(
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _quote()),
            _latestButton(),
            if (compact) ...[const SizedBox(width: 8), _fullRangeButton()],
          ],
        ),
        if (compact)
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              'BTC/USD · 로그 축',
              style: TextStyle(fontSize: 10, color: CycleTimingComparisonStyle.price),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          _normalToolbar(),
          const SizedBox(height: 10),
        ],
        if (compact)
          Expanded(child: chart)
        else
          SizedBox(height: 280 + math.max(0, scale - 1) * 40, child: chart),
        Padding(
          padding: EdgeInsets.only(left: axisWidth, right: _rightPadding),
          child: ChartDateAxis(firstDate: _firstDate, startDay: _startDay, endDay: _endDay),
        ),
        const SizedBox(height: 4),
        CycleTimingComparisonLegend(
          showPrice: showPrice,
          showHalving: halvingDays.isNotEmpty,
          showProgress: progressDays.isNotEmpty,
          showRange: ranges.isNotEmpty,
        ),
        SizedBox(height: compact ? 4 : 12),
        Text(
          '표시 기간 · ${_dateFormat.format(_date(_startDay))} ~ ${_dateFormat.format(_date(_endDay))}',
          style: const TextStyle(fontSize: 11, color: CycleTimingComparisonStyle.muted),
        ),
        const SizedBox(height: 2),
        ChartRangeSelector(
          overviewPoints: _overview,
          values: RangeValues(_startDay / _fullEnd, _endDay / _fullEnd),
          minimumSpan: _minimumSpan / _fullEnd,
          firstDate: _firstDate,
          lastDate: _date(_fullEnd),
          onChanged: _changeRange,
          onChangeStart: () => _draggingRange = true,
          onChangeEnd: _endRangeDrag,
          height: compact ? 48 : 60,
        ),
      ],
    );
  }

  Widget _buildPriceChart(
    double axisWidth,
    List<int> halvingDays,
    List<int> progressDays,
    List<VerticalRangeAnnotation> ranges,
  ) {
    final selected = _displayDay;
    return Padding(
      padding: const EdgeInsets.only(right: _rightPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotWidth = math.max(1.0, constraints.maxWidth - axisWidth);
          final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
          final tickCount = (constraints.maxHeight / (44 * scale)).floor().clamp(2, 6);
          final rawStep = (_maxY - _minY) / tickCount;
          final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
          final tickStep =
              [1.0, 2.0, 2.5, 5.0, 10.0].firstWhere((step) => step * magnitude >= rawStep) *
              magnitude;
          final chart = LineChart(
            LineChartData(
              minX: _startDay.toDouble(),
              maxX: _endDay.toDouble(),
              minY: _minY,
              maxY: _maxY,
              clipData: const FlClipData.all(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: tickStep,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: CycleTimingComparisonStyle.grid, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: axisWidth,
                    interval: tickStep,
                    minIncluded: false,
                    maxIncluded: false,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      space: 6,
                      fitInside: SideTitleFitInsideData(
                        enabled: true,
                        axisPosition: meta.axisPosition,
                        parentAxisSize: meta.parentAxisSize,
                        distanceFromEdge: 0,
                      ),
                      child: Text(
                        _axisPrice(math.pow(10, value).toDouble()),
                        style: const TextStyle(
                          fontSize: 10,
                          color: CycleTimingComparisonStyle.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: ranges),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  for (final day in halvingDays)
                    VerticalLine(
                      x: day.toDouble(),
                      color: CycleTimingComparisonStyle.halving,
                      strokeWidth: 1,
                    ),
                  for (final day in progressDays)
                    VerticalLine(
                      x: day.toDouble(),
                      color: CycleTimingComparisonStyle.progress,
                      strokeWidth: 1.3,
                      dashArray: [4, 4],
                    ),
                  if (selected != null)
                    VerticalLine(
                      x: selected.toDouble(),
                      color: CycleTimingComparisonStyle.text.withValues(alpha: .45),
                      strokeWidth: 1,
                      dashArray: [2, 4],
                    ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _spots,
                  color: CycleTimingComparisonStyle.price,
                  barWidth: 1.7,
                  isCurved: false,
                  dotData: FlDotData(
                    checkToShowDot: (spot, _) => !spot.isNull() && spot.x == selected,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 4,
                      color: CycleTimingComparisonStyle.price,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  final position = event.localPosition;
                  if (!event.isInterestedForInteractions || position == null) {
                    return;
                  }
                  // 없는 날짜의 가격을 보간하거나 다른 날의 종가로 바꾸지 않습니다.
                  final fraction = (position.dx / plotWidth).clamp(0.0, 1.0);
                  _selectDate(_startDay + (_endDay - _startDay) * fraction);
                },
              ),
            ),
            duration: Duration.zero,
          );
          return Stack(
            children: [
              Positioned.fill(child: chart),
              Positioned.fill(
                left: axisWidth,
                child: IgnorePointer(child: _buildProgressLabels(progressDays, plotWidth)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressLabels(List<int> days, double plotWidth) {
    if (days.isEmpty || plotWidth <= 0) {
      return const SizedBox.shrink();
    }
    final label = '${(widget.comparison.currentProgress * 100).toStringAsFixed(1)}%';
    final scaler = MediaQuery.textScalerOf(context);
    final style = DefaultTextStyle.of(context).style.copyWith(
      fontSize: 10,
      height: 1.2,
      fontWeight: MediaQuery.boldTextOf(context) ? FontWeight.w700 : FontWeight.w600,
      color: CycleTimingComparisonStyle.progress,
    );
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: ui.TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = math.min(plotWidth, painter.width.ceilToDouble() + 8);
    final height = painter.height.ceilToDouble() + 4;
    painter.dispose();
    final rowEnds = <double>[];
    final labels = <Widget>[];
    for (final day in days) {
      final x = (day - _startDay) / (_endDay - _startDay) * plotWidth;
      final left = (x - width / 2).clamp(0.0, math.max(0.0, plotWidth - width)).toDouble();
      var row = 0;
      while (row < rowEnds.length && left < rowEnds[row] + 6) {
        row++;
      }
      if (row == rowEnds.length) {
        rowEnds.add(left + width);
      } else {
        rowEnds[row] = left + width;
      }
      labels.add(
        Positioned(
          left: left,
          top: 4 + row * (height + 4),
          width: width,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: Text(
              label,
              style: style,
              textScaler: scaler,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          ),
        ),
      );
    }
    // 텍스트는 가격선·선택 안내선 위에 그리고, 터치는 차트로 통과시킵니다.
    return Stack(children: labels);
  }

  String _axisPrice(double price) {
    final unit = price >= 1000000
        ? 1000000.0
        : price >= 1000
        ? 1000.0
        : 1.0;
    final suffix = unit == 1000000
        ? 'M'
        : unit == 1000
        ? 'K'
        : '';
    final value = price / unit;
    final decimals = (3 - (math.log(value) / math.ln10).floor()).clamp(0, 8);
    var label = value.toStringAsFixed(decimals);
    if (label.contains('.')) {
      label = label.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return '\$$label$suffix';
  }
}
