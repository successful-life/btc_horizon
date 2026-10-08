import 'dart:math' as math;

import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';
import 'package:btc_horizon/models/cycle_timing_analysis_chart_model.dart';
import 'package:btc_horizon/models/cycle_timing_chart_point_model.dart';
import 'package:btc_horizon/models/cycle_timing_interval_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import 'chart_range_selector.dart';
import 'cycle_timing_interval_strip.dart';

enum CycleTimingIntervalMode { sameType, alternating }

// 화면을 확대했다가 돌아와도 표시 기간·비교 방식·선택 날짜를 이어갑니다.
class CycleTimingChartView {
  final CycleTimingIntervalMode mode;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? selectedDate;

  const CycleTimingChartView({
    this.mode = CycleTimingIntervalMode.sameType,
    this.startDate,
    this.endDate,
    this.selectedDate,
  });
}

class CycleTimingAnalysisChart extends StatefulWidget {
  final CycleTimingAnalysisChartModel data;
  final bool fillAvailableSpace;
  final CycleTimingChartView? initialView;
  final ValueChanged<CycleTimingChartView>? onViewChanged;
  // 일반 화면에서만 전달합니다. 확대 화면에서는 버튼을 표시하지 않습니다.
  final VoidCallback? onExpand;

  const CycleTimingAnalysisChart({
    super.key,
    required this.data,
    this.fillAvailableSpace = false,
    this.initialView,
    this.onViewChanged,
    this.onExpand,
  });

  @override
  State<CycleTimingAnalysisChart> createState() => _CycleTimingAnalysisChartState();
}

class _CycleTimingAnalysisChartState extends State<CycleTimingAnalysisChart> {
  static const _priceColor = Color(0xFF0891B2);
  static const _estimateColor = Color(0xFF7C5CC4);
  static const _currentColor = Color(0xFF64748B);
  static const _guideColor = Color(0xFF64748B);
  static const _textColor = Color(0xFF172033);
  static const _mutedColor = Color(0xFF667085);
  static const _leftAxisWidth = 52.0;
  static const _rightPadding = 8.0;
  // 전체 기록의 시간 비율을 유지하면서 예상 범위 뒤에 조금 여유를 둡니다.
  static const _futurePaddingDays = 90;
  static const _estimateLookbackDays = 365;
  static final _dateFormat = DateFormat('yyyy/MM/dd');
  static final _priceFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  CycleTimingIntervalMode _mode = CycleTimingIntervalMode.sameType;
  DateTime _firstDate = DateTime.utc(2000);
  List<FlSpot> _spots = [];
  List<Offset?> _overview = [];
  List<int> _days = [];
  Map<int, CycleTimingChartPointModel> _pricesByDay = {};
  Map<int, double> _logPricesByDay = {};
  int _fullEnd = 1;
  int _startDay = 0;
  int _endDay = 1;
  int? _selectedDay;
  double _minY = 0;
  double _maxY = 1;
  bool _isRangeDragging = false;

  int get _minimumSpan => math.min(30, _fullEnd);
  bool get _hasData => _days.length >= 2;
  bool get _isFullRange => _startDay == 0 && _endDay == _fullEnd;
  bool get _compareSameType => _mode == CycleTimingIntervalMode.sameType;
  DateTime get _forecastStartDate =>
      widget.data.analysis.targetEstimate.startDateFor(sameType: _compareSameType);
  int _day(DateTime date) => calendarDayKey(date) - calendarDayKey(_firstDate);
  DateTime _date(int day) => _firstDate.add(Duration(days: day));

  CycleTimingChartView get _view => CycleTimingChartView(
    mode: _mode,
    startDate: _isFullRange ? null : _date(_startDay),
    endDate: _isFullRange ? null : _date(_endDay),
    selectedDate: _selectedDay == null ? null : _date(_selectedDay!),
  );

  @override
  void initState() {
    super.initState();
    _prepare(widget.initialView ?? const CycleTimingChartView());
  }

  @override
  void didUpdateWidget(covariant CycleTimingAnalysisChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      final view = _view;
      final followRightEdge = _endDay == _fullEnd;
      _prepare(view, followRightEdge: followRightEdge);
    }
  }

  void _prepare(CycleTimingChartView view, {bool followRightEdge = false}) {
    final points = widget.data.pricePoints;
    _mode = view.mode;
    _spots = [];
    _overview = [];
    _days = [];
    _pricesByDay = {};
    _logPricesByDay = {};
    _selectedDay = null;
    if (points.length < 2) return;

    _firstDate = DateTime.utc(
      points.first.date.year,
      points.first.date.month,
      points.first.date.day,
    );
    final logPrices = points.map((p) => math.log(p.closePrice) / math.ln10);
    final overviewMin = logPrices.reduce(math.min).floorToDouble();
    final overviewMax = math.max(overviewMin + 1, logPrices.reduce(math.max).ceilToDouble());
    // 미니 차트는 전체 기록의 축을 유지하고, 메인 차트만 조절합니다.
    if (!_isRangeDragging) {
      _minY = overviewMin;
      _maxY = overviewMax;
    }
    // 미래에는 예상 날짜와 기간만 표시합니다. 종가를 연장하거나 보간하지 않습니다.
    _fullEnd =
        math.max(
          math.max(_day(points.last.date), _day(widget.data.analysis.asOfDate)),
          _day(widget.data.analysis.targetEstimate.rangeEndDate),
        ) +
        _futurePaddingDays;

    int? previousDay;
    for (final point in points) {
      final day = _day(point.date);
      if (previousDay != null && day - previousDay > 1) {
        _spots.add(FlSpot.nullSpot);
        _overview.add(null);
      }
      final logPrice = math.log(point.closePrice) / math.ln10;
      _logPricesByDay[day] = logPrice;
      _days.add(day);
      _pricesByDay[day] = point;
      _spots.add(FlSpot(day.toDouble(), logPrice));
      _overview.add(Offset(day / _fullEnd, (logPrice - overviewMin) / (overviewMax - overviewMin)));
      previousDay = day;
    }

    if (view.startDate == null || view.endDate == null) {
      _startDay = 0;
      _endDay = _fullEnd;
    } else {
      final span = (calendarDayKey(view.endDate!) - calendarDayKey(view.startDate!)).clamp(
        _minimumSpan,
        _fullEnd,
      );
      _startDay = followRightEdge
          ? _fullEnd - span
          : _day(view.startDate!).clamp(0, _fullEnd - span);
      _endDay = _startDay + span;
    }
    if (view.selectedDate != null) {
      final day = _day(view.selectedDate!);
      if (day >= _startDay && day <= _endDay) _selectedDay = day;
    }
    if (!_isRangeDragging) _fitVisibleY();
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
    if (_selectedDay != null) return _selectedDay;
    final last = _lowerBound(_endDay + 1) - 1;
    return last >= 0 && _days[last] >= _startDay ? _days[last] : null;
  }

  void _reportView() => widget.onViewChanged?.call(_view);

  void _fitVisibleY() {
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (var i = _lowerBound(_startDay); i < _days.length && _days[i] <= _endDay; i++) {
      final value = _logPricesByDay[_days[i]]!;
      low = math.min(low, value);
      high = math.max(high, value);
    }
    // 미래만 선택하거나 가격이 전부 누락된 구간은 마지막 유효 축을 유지합니다.
    if (!low.isFinite || !high.isFinite) return;
    // 일직선 또는 값 하나뿐인 경우에도 축이 0폭이 되지 않게 합니다.
    final span = math.max(high - low, 0.02);
    final middle = (low + high) / 2;
    _minY = middle - span * 0.6;
    _maxY = middle + span * 0.6;
  }

  void _beginRangeDrag() => _isRangeDragging = true;

  void _endRangeDrag() {
    if (!_isRangeDragging) return;
    setState(() {
      _isRangeDragging = false;
      _fitVisibleY();
    });
  }

  void _changeRange(RangeValues range) {
    final start = (range.start * _fullEnd).round().clamp(0, _fullEnd - _minimumSpan);
    final end = (range.end * _fullEnd).round().clamp(start + _minimumSpan, _fullEnd);
    if (start == _startDay && end == _endDay) return;
    setState(() {
      _startDay = start;
      _endDay = end;
      if (_selectedDay != null && (_selectedDay! < start || _selectedDay! > end)) {
        _selectedDay = null;
      }
      // 드래그 중에는 가로 범위만 바꾸고, 손을 뗀 뒤 세로축을 맞춥니다.
      // 버튼·바깥 영역 탭·접근성 조작에는 즉시 적용합니다.
      if (!_isRangeDragging) _fitVisibleY();
    });
    _reportView();
  }

  void _selectDate(double x) {
    final day = x.round().clamp(_startDay, _endDay);
    if (day == _selectedDay) return;
    setState(() => _selectedDay = day);
    _reportView();
  }

  void _goToLatest() {
    final last = _days.last;
    final span = _endDay - _startDay;
    setState(() {
      if (last < _startDay || last > _endDay) {
        // 최근 종가를 표시 범위에 포함하고, 조금 뒤의 날짜도 보이도록 합니다.
        _endDay = math.min(_fullEnd, last + span ~/ 5).clamp(span, _fullEnd);
        _startDay = _endDay - span;
      }
      _selectedDay = last;
      if (!_isRangeDragging) _fitVisibleY();
    });
    _reportView();
  }

  (int, int) get _estimateWindow {
    final estimate = widget.data.analysis.targetEstimate;
    // 저점 → 다음 고점처럼 기간이 길어도 예측의 출발점까지 함께 보여 줍니다.
    final anchor = math.min(
      _day(_forecastStartDate),
      math.min(_days.last, _day(estimate.rangeStartDate)),
    );
    final start = (anchor - _estimateLookbackDays).clamp(0, _fullEnd - _minimumSpan);
    return (start, _fullEnd);
  }

  bool get _isEstimateWindow {
    final (start, end) = _estimateWindow;
    return _startDay == start && _endDay == end;
  }

  void _setWindow(int start, int end) {
    _changeRange(RangeValues(start / _fullEnd, end / _fullEnd));
  }

  Widget _rangeActions() {
    Widget button(String label, bool selected, VoidCallback onPressed) => Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: selected ? _priceColor : _mutedColor,
          backgroundColor: selected ? const Color(0xFFEAF6FA) : const Color(0xFFF7F9FC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button('전체 기간', _isFullRange, () => _setWindow(0, _fullEnd)),
        const SizedBox(width: 4),
        button('예상 구간 보기', _isEstimateWindow, () {
          final (start, end) = _estimateWindow;
          _setWindow(start, end);
        }),
      ],
    );
  }

  (List<CycleTimingIntervalModel>, List<CycleTimingIntervalModel>, String, String, Color, Color)
  get _intervals => switch (_mode) {
    CycleTimingIntervalMode.sameType => (
      widget.data.topToTopIntervals,
      widget.data.bottomToBottomIntervals,
      '고점 → 고점',
      '저점 → 저점',
      const Color(0xFFE88A18),
      const Color(0xFF4B8DDB),
    ),
    CycleTimingIntervalMode.alternating => (
      widget.data.analysis.bottomToTopIntervals,
      widget.data.analysis.topToBottomIntervals,
      '저점 → 고점',
      '고점 → 저점',
      const Color(0xFF16834A),
      const Color(0xFFDC4446),
    ),
  };

  List<CycleTimingIntervalModel> _completed(List<CycleTimingIntervalModel> intervals) => intervals
      .where((i) => calendarDayKey(i.endDate) <= calendarDayKey(widget.data.analysis.asOfDate))
      .toList();

  Widget _modeSelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFEAECF0)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<CycleTimingIntervalMode>(
        value: _mode,
        isExpanded: true,
        style: TextStyle(
          fontSize: widget.fillAvailableSpace ? 12 : 14,
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
        items: const [
          DropdownMenuItem(
            value: CycleTimingIntervalMode.sameType,
            child: Text('고점 → 고점 · 저점 → 저점'),
          ),
          DropdownMenuItem(
            value: CycleTimingIntervalMode.alternating,
            child: Text('저점 → 고점 · 고점 → 저점'),
          ),
        ],
        onChanged: (mode) {
          if (mode != null) {
            final followEstimateWindow = _isEstimateWindow;
            setState(() => _mode = mode);
            // '예상 구간 보기' 중에는 모드를 바꿔도 새 출발점까지 보여 줍니다.
            if (followEstimateWindow) {
              final (start, end) = _estimateWindow;
              _setWindow(start, end);
            }
            _reportView();
          }
        },
      ),
    ),
  );

  Widget _quote() {
    final day = _displayDay;
    final point = day == null ? null : _pricesByDay[day];
    final label = _selectedDay != null
        ? '선택 날짜'
        : day == _days.last
        ? '최근 종가'
        : '기간 내 마지막';
    final dateLabel = day == null
        ? '선택 기간에 종가가 없습니다.'
        : '$label · ${_dateFormat.format(_date(day))}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateLabel, style: const TextStyle(fontSize: 11, color: _mutedColor)),
        const SizedBox(height: 2),
        Text(
          point == null ? '가격 데이터 없음' : _priceFormat.format(point.closePrice),
          style: TextStyle(
            fontSize: point == null
                ? 12
                : widget.fillAvailableSpace
                ? 16
                : 20,
            color: point == null ? _mutedColor : _priceColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _latestButton() => TextButton(
    onPressed: _displayDay == _days.last ? null : _goToLatest,
    style: TextButton.styleFrom(
      foregroundColor: _priceColor,
      minimumSize: const Size(64, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    child: const Text('최근으로'),
  );

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('차트를 그릴 가격 데이터가 부족합니다.'),
      );
    }

    final (first, second, firstLabel, secondLabel, firstColor, secondColor) = _intervals;
    final firstCompleted = _completed(first);
    final secondCompleted = _completed(second);
    final estimate = widget.data.analysis.targetEstimate;
    final forecastStart = _forecastStartDate;
    final showForecastArrow =
        estimate.durationDaysFor(sameType: _compareSameType) > 0 &&
        _day(estimate.centerDate) > _startDay &&
        _day(forecastStart) < _endDay;
    final forecastLabel = switch (estimate.type) {
      CycleTimingEstimateType.top => '${_compareSameType ? '고점' : '저점'} → 예상 고점',
      CycleTimingEstimateType.bottom => '${_compareSameType ? '저점' : '고점'} → 예상 저점',
    };
    final boundaryDays = <int>{
      for (final interval in [...firstCompleted, ...secondCompleted])
        for (final date in [interval.startDate, interval.endDate])
          if (_day(date) >= _startDay &&
              _day(date) <= _endDay &&
              _pricesByDay.containsKey(_day(date)))
            _day(date),
      if (showForecastArrow &&
          _day(forecastStart) >= _startDay &&
          _day(forecastStart) <= _endDay &&
          _pricesByDay.containsKey(_day(forecastStart)))
        _day(forecastStart),
    }.toList()..sort();
    final compact = widget.fillAvailableSpace;
    bool visible(int day) => day >= _startDay && day <= _endDay;
    bool overlaps(CycleTimingIntervalModel interval) =>
        _day(interval.endDate) > _startDay && _day(interval.startDate) < _endDay;
    final showEstimate =
        math.max(_startDay, _day(estimate.rangeStartDate)) <
        math.min(_endDay, _day(estimate.rangeEndDate));
    final firstVisiblePrice = _lowerBound(_startDay);
    final showPrice = firstVisiblePrice < _days.length && _days[firstVisiblePrice] <= _endDay;

    return Column(
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact)
          Row(
            children: [
              Expanded(flex: 5, child: _modeSelector()),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: _quote()),
              _latestButton(),
              const SizedBox(width: 8),
              _rangeActions(),
            ],
          )
        else ...[
          _modeSelector(),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _quote()),
              _latestButton(),
            ],
          ),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: _rangeActions()),
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BTC/USD · 일별 종가 · 로그 축',
                  style: TextStyle(fontSize: 11, color: _priceColor),
                ),
              ),
              if (widget.onExpand != null)
                IconButton(
                  tooltip: '차트 확대',
                  onPressed: widget.onExpand,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.fullscreen_rounded),
                  color: _mutedColor,
                ),
            ],
          ),
        ],
        SizedBox(height: compact ? 4 : 10),
        if (compact)
          Expanded(child: _buildPriceChart(boundaryDays))
        else
          SizedBox(height: 280, child: _buildPriceChart(boundaryDays)),
        Padding(
          padding: const EdgeInsets.only(left: _leftAxisWidth, right: _rightPadding),
          child: CycleTimingIntervalStrip(
            firstDate: _firstDate,
            startDay: _startDay,
            endDay: _endDay,
            firstIntervals: firstCompleted,
            secondIntervals: secondCompleted,
            firstLabel: firstLabel,
            secondLabel: secondLabel,
            firstColor: firstColor,
            secondColor: secondColor,
            guideDays: boundaryDays.toSet(),
            estimate: estimate,
            compareSameType: _compareSameType,
            estimateColor: _estimateColor,
            compact: compact,
          ),
        ),
        Wrap(
          spacing: compact ? 10 : 12,
          runSpacing: 4,
          children: [
            if (firstCompleted.any(overlaps)) _legend(firstColor, firstLabel),
            if (secondCompleted.any(overlaps)) _legend(secondColor, secondLabel),
            if (showForecastArrow) _legend(_estimateColor, forecastLabel, dashed: true),
            if (showPrice) _legend(_priceColor, compact ? 'BTC 종가 · 로그 축' : 'BTC 종가'),
            if (boundaryDays.isNotEmpty) _legend(_guideColor, '주기 기준일', dashed: true),
            if (visible(_day(widget.data.analysis.asOfDate)))
              _legend(_currentColor, '분석 기준일', dashed: true),
            if (visible(_day(estimate.centerDate))) _legend(_estimateColor, '예상 중심일', dashed: true),
            if (showEstimate) _legend(_estimateColor, '예상 범위', range: true),
          ],
        ),
        SizedBox(height: compact ? 4 : 10),
        Text(
          '표시 기간 · ${_dateFormat.format(_date(_startDay))} ~ ${_dateFormat.format(_date(_endDay))}',
          style: const TextStyle(fontSize: 11, color: _mutedColor),
        ),
        const SizedBox(height: 2),
        ChartRangeSelector(
          overviewPoints: _overview,
          values: RangeValues(_startDay / _fullEnd, _endDay / _fullEnd),
          minimumSpan: _minimumSpan / _fullEnd,
          firstDate: _firstDate,
          lastDate: _date(_fullEnd),
          onChanged: _changeRange,
          onChangeStart: _beginRangeDrag,
          onChangeEnd: _endRangeDrag,
          height: compact ? 48 : 60,
        ),
      ],
    );
  }

  Widget _buildPriceChart(List<int> boundaryDays) {
    final estimate = widget.data.analysis.targetEstimate;
    final rangeStart = math.max(_startDay, _day(estimate.rangeStartDate)).toDouble();
    final rangeEnd = math.min(_endDay, _day(estimate.rangeEndDate)).toDouble();
    final current = _day(widget.data.analysis.asOfDate);
    final center = _day(estimate.centerDate);
    final selected = _displayDay;
    bool visible(int day) => day >= _startDay && day <= _endDay;

    return Padding(
      padding: const EdgeInsets.only(right: _rightPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotWidth = math.max(1.0, constraints.maxWidth - _leftAxisWidth);
          // 1보다 작은 로그 간격도 사용해 확대 시 눈금이 사라지지 않게 합니다.
          final rawStep = (_maxY - _minY) / (constraints.maxHeight < 180 ? 3 : 5);
          final magnitude = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
          final tickStep =
              [1.0, 2.0, 2.5, 5.0, 10.0].firstWhere((step) => step * magnitude >= rawStep) *
              magnitude;
          return LineChart(
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
                    const FlLine(color: Color(0xFFE8EDF3), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: _leftAxisWidth,
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
                        style: const TextStyle(fontSize: 10, color: _mutedColor),
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                // 실제 종가 위치에서 차트 아래까지 연결합니다.
                for (final day in boundaryDays)
                  LineChartBarData(
                    spots: [
                      FlSpot(day.toDouble(), _logPricesByDay[day]!),
                      FlSpot(day.toDouble(), _minY),
                    ],
                    color: _guideColor.withValues(alpha: 0.55),
                    barWidth: 1,
                    dashArray: [4, 4],
                    isCurved: false,
                    dotData: const FlDotData(show: false),
                  ),
                LineChartBarData(
                  spots: _spots,
                  color: _priceColor,
                  barWidth: 1.6,
                  isCurved: false,
                  dotData: FlDotData(
                    checkToShowDot: (spot, _) =>
                        !spot.isNull() &&
                        (boundaryDays.contains(spot.x.toInt()) || spot.x == selected),
                    getDotPainter: (spot, percent, bar, index) {
                      final isSelected = spot.x == selected;
                      return FlDotCirclePainter(
                        radius: isSelected ? 4 : 3,
                        color: isSelected ? _priceColor : Colors.white,
                        strokeWidth: isSelected ? 2 : 1.5,
                        strokeColor: isSelected ? Colors.white : _guideColor,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              rangeAnnotations: RangeAnnotations(
                verticalRangeAnnotations: [
                  if (rangeEnd > rangeStart)
                    VerticalRangeAnnotation(
                      x1: rangeStart,
                      x2: rangeEnd,
                      color: _estimateColor.withValues(alpha: 0.10),
                    ),
                ],
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  if (visible(current))
                    VerticalLine(
                      x: current.toDouble(),
                      color: _currentColor,
                      strokeWidth: 1,
                      dashArray: [3, 4],
                    ),
                  if (visible(center))
                    VerticalLine(
                      x: center.toDouble(),
                      color: _estimateColor,
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                    ),
                  if (selected != null && visible(selected))
                    VerticalLine(
                      x: selected.toDouble(),
                      color: _textColor.withValues(alpha: 0.55),
                      strokeWidth: 1,
                      dashArray: [2, 4],
                    ),
                ],
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  final position = event.localPosition;
                  if (!event.isInterestedForInteractions || position == null) return;
                  // 터치 위치에서 달력 날짜를 고릅니다. 누락일/미래일을 종가가 있는 날로 바꾸지 않습니다.
                  final fraction = (position.dx / plotWidth).clamp(0.0, 1.0);
                  _selectDate(_startDay + (_endDay - _startDay) * fraction);
                },
              ),
            ),
            duration: Duration.zero,
          );
        },
      ),
    );
  }

  Widget _legend(Color color, String label, {bool dashed = false, bool range = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 16,
        height: 9,
        child: range
            ? ColoredBox(color: color.withValues(alpha: 0.12))
            : Center(
                child: dashed
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < 3; i++)
                            SizedBox(width: 4, height: 1.5, child: ColoredBox(color: color)),
                        ],
                      )
                    : SizedBox(width: 16, height: 1.5, child: ColoredBox(color: color)),
              ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(fontSize: widget.fillAvailableSpace ? 10 : 11, color: _mutedColor),
      ),
    ],
  );

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
