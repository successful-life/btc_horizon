import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/widgets/mvrv_range_selector.dart';

class MvrvHistoryChart extends StatefulWidget {
  final MvrvHistoryModel history;

  // true일 때 부모가 제공하는 제한된 높이 안에서 차트가 남은 공간을 채웁니다.
  final bool fillAvailableSpace;

  const MvrvHistoryChart({super.key, required this.history, this.fillAvailableSpace = false});

  @override
  State<MvrvHistoryChart> createState() => _MvrvHistoryChartState();
}

class _MvrvHistoryChartState extends State<MvrvHistoryChart> {
  static final _chartStartDate = DateTime.utc(2010, 10, 1);
  static final _dateFormat = DateFormat('yyyy/MM/dd');
  static final _axisDateFormat = DateFormat('yy.MM');
  static final _shortAxisDateFormat = DateFormat('MM/dd');
  static final _priceFormat = NumberFormat('#,##0.00');

  static const _priceColor = Color(0xFF0891B2);
  static const _mvrvColor = Color(0xFFF59E0B);
  static const _textColor = Color(0xFF172033);
  static const _secondaryTextColor = Color(0xFF667085);

  // MVRV Z Score 고점 및 저점 영역 표시
  static const _bottomZoneMin = -0.5;
  static const _bottomZoneMax = 0.5;
  static const _topZoneMin = 7.0;
  static const _topZoneMax = 9.0;
  static const _bottomZoneColor = Color(0xFF16834A);
  static const _topZoneColor = Color(0xFFDC4446);

  List<MvrvHistoryPointModel> _points = [];
  List<FlSpot> _priceSpots = [];
  List<FlSpot> _mvrvSpots = [];
  Map<int, int> _indexByDay = {};
  List<int> _days = [];
  List<Offset?> _overviewPoints = [];

  int _viewStartDay = 0;
  int _viewEndDay = 1;
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = -1;

  // 선택 폭이 지나치게 좁아지지 않도록 최소 30일 간격을 유지합니다.
  int get _minimumSpanDays => math.min(30, _maxX.round());
  DateTime _dateAtDay(int day) => _points.first.date.add(Duration(days: day));

  MvrvHistoryPointModel? get _selectedPoint {
    if (_firstVisibleIndex > _lastVisibleIndex) {
      return null;
    }
    return _points[_selectedIndex ?? _lastVisibleIndex];
  }

  bool get _isAtLatest => _viewEndDay == _maxX.round() && _selectedIndex == null;

  double _maxX = 1;
  double _priceLogMin = 0;
  double _priceLogMax = 1;
  double _zMin = 0;
  double _zMax = 1;
  double _zTickStep = 1;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant MvrvHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.history, widget.history)) {
      final selectedDate = _selectedIndex == null ? null : _points[_selectedIndex!].date;
      final hadData = _points.length >= 2;
      final wasFullRange = _viewStartDay == 0 && _viewEndDay == _maxX.round();
      final wasAtEnd = _viewEndDay == _maxX.round();
      _prepareData(
        selectedDate: selectedDate,
        rangeStart: hadData && !wasFullRange ? _dateAtDay(_viewStartDay) : null,
        rangeEnd: hadData && !wasFullRange ? _dateAtDay(_viewEndDay) : null,
        followLatest: wasAtEnd,
      );
    }
  }

  double _logPrice(double price) => math.log(price) / math.ln10;

  double _priceToY(double price) =>
      (_logPrice(price) - _priceLogMin) / (_priceLogMax - _priceLogMin);

  double _zToY(double zScore) => (zScore - _zMin) / (_zMax - _zMin);

  double _yToZ(double y) => _zMin + y * (_zMax - _zMin);

  bool _isZTick(double y) {
    final z = _yToZ(y);
    final closestTick = (z / _zTickStep).roundToDouble() * _zTickStep;
    return (z - closestTick).abs() < 0.000001;
  }

  void _prepareData({
    DateTime? selectedDate,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    bool followLatest = false,
  }) {
    // 원본은 유지하고 표시용 목록만 필터링합니다.
    _points = widget.history.points.where((point) {
      return !point.date.isBefore(_chartStartDate) &&
          !point.date.isAfter(widget.history.completeThrough);
    }).toList();

    _priceSpots = [];
    _mvrvSpots = [];
    _indexByDay = {};
    _days = [];
    _overviewPoints = [];
    _selectedIndex = null;
    _viewStartDay = 0;
    _viewEndDay = 1;
    _firstVisibleIndex = 0;
    _lastVisibleIndex = -1;
    if (_points.length < 2) {
      return;
    }

    final logPrices = _points.map((p) => _logPrice(p.btcPriceUsd));
    final minLog = logPrices.reduce((a, b) => a < b ? a : b);
    final maxLog = logPrices.reduce((a, b) => a > b ? a : b);
    _priceLogMin = minLog.floorToDouble();
    _priceLogMax = maxLog.ceilToDouble();
    if (_priceLogMax <= _priceLogMin) {
      _priceLogMax = _priceLogMin + 1;
    }

    final zValues = _points.map((p) => p.mvrvZScore);
    final minZ = zValues.reduce((a, b) => a < b ? a : b);
    final maxZ = zValues.reduce((a, b) => a > b ? a : b);
    // 데이터와 참고 구간을 모두 포함합니다. 극값을 잘라내지 않습니다.
    // 축 끝을 큰 눈금 간격에 맞춰 -5, 15 등으로 불필요하게 늘리지 않습니다.
    _zMin = math.min((_bottomZoneMin - 0.25).floorToDouble(), (minZ - 0.1).floorToDouble());
    _zMax = math.max((_topZoneMax + 0.25).ceilToDouble(), (maxZ + 0.1).ceilToDouble());
    _zTickStep = (_zMax - _zMin) <= 16 ? 2.0 : _niceStep((_zMax - _zMin) / 5);

    final firstDate = _points.first.date;
    _maxX = _points.last.date.difference(firstDate).inDays.toDouble();
    for (var i = 0; i < _points.length; i++) {
      final point = _points[i];
      final day = point.date.difference(firstDate).inDays;

      // 누락된 날짜는 선을 끊어 표시합니다.
      if (i > 0 && point.date.difference(_points[i - 1].date).inDays > 1) {
        _priceSpots.add(FlSpot.nullSpot);
        _mvrvSpots.add(FlSpot.nullSpot);
        _overviewPoints.add(null);
      }

      _days.add(day);
      _overviewPoints.add(Offset(day / _maxX, _priceToY(point.btcPriceUsd)));
      _indexByDay[day] = i;
      _priceSpots.add(FlSpot(day.toDouble(), _priceToY(point.btcPriceUsd)));
      _mvrvSpots.add(FlSpot(day.toDouble(), _zToY(point.mvrvZScore)));
      if (selectedDate == point.date) {
        _selectedIndex = i;
      }
    }

    if (rangeStart == null || rangeEnd == null) {
      _setWindow(0, _maxX.round());
    } else {
      final span = rangeEnd.difference(rangeStart).inDays.clamp(_minimumSpanDays, _maxX.round());
      final start = followLatest
          ? _maxX.round() - span
          : rangeStart.difference(firstDate).inDays.clamp(0, _maxX.round() - span);
      _setWindow(start, start + span);
    }
  }

  // 누락된 날짜가 있어도 실제 데이터가 존재하는 범위만 선택합니다.
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

  void _setWindow(int start, int end) {
    _viewStartDay = start;
    _viewEndDay = end;
    _firstVisibleIndex = _lowerBound(start);
    _lastVisibleIndex = _lowerBound(end + 1) - 1;

    final selectedIndex = _selectedIndex;
    if (selectedIndex != null &&
        (selectedIndex < _firstVisibleIndex || selectedIndex > _lastVisibleIndex)) {
      _selectedIndex = null;
    }
  }

  void _changeRange(RangeValues values) {
    final start = (values.start * _maxX).round().clamp(0, _maxX.round() - _minimumSpanDays);
    final end = (values.end * _maxX).round().clamp(start + _minimumSpanDays, _maxX.round());
    if (start == _viewStartDay && end == _viewEndDay) {
      return;
    }
    setState(() => _setWindow(start, end));
  }

  void _goToLatest() {
    // 확대 비율은 유지하고 마지막 데이터가 보이도록 기간을 이동합니다.
    final span = _viewEndDay - _viewStartDay;
    setState(() {
      _selectedIndex = null;
      _setWindow(_maxX.round() - span, _maxX.round());
    });
  }

  Widget _buildRangeSelector() {
    final rangeText =
        '${_dateFormat.format(_dateAtDay(_viewStartDay))}'
        ' ~ ${_dateFormat.format(_dateAtDay(_viewEndDay))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '표시 기간 · $rangeText',
          style: const TextStyle(fontSize: 11, color: _secondaryTextColor),
        ),
        const SizedBox(height: 4),
        MvrvRangeSelector(
          overviewPoints: _overviewPoints,
          values: RangeValues(_viewStartDay / _maxX, _viewEndDay / _maxX),
          minimumSpan: _minimumSpanDays / _maxX,
          firstDate: _points.first.date,
          lastDate: _points.last.date,
          onChanged: _changeRange,
          height: widget.fillAvailableSpace ? 48 : 60,
        ),
      ],
    );
  }

  // 축 눈금 간격을 1, 2, 5 × 10ⁿ 중 하나로 선택합니다.
  double _niceStep(double roughStep) {
    final power = math.pow(10, (math.log(roughStep) / math.ln10).floor()).toDouble();
    final fraction = roughStep / power;
    final factor = fraction <= 1
        ? 1
        : fraction <= 2
        ? 2
        : fraction <= 5
        ? 5
        : 10;
    return factor * power;
  }

  void _selectDay(double x) {
    final index = _indexByDay[x.round()];
    if (index == null ||
        index < _firstVisibleIndex ||
        index > _lastVisibleIndex ||
        index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_points.length < 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('표시할 기간의 MVRV 데이터가 부족합니다.'),
      );
    }

    final selected = _selectedPoint;
    final selectedX = selected?.date.difference(_points.first.date).inDays.toDouble();

    return Column(
      mainAxisSize: widget.fillAvailableSpace ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummary(selected),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(
              child: Text('BTC/USD · 로그 축', style: TextStyle(fontSize: 11, color: _priceColor)),
            ),
            Expanded(
              child: Text(
                'MVRV Z-Score',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: _mvrvColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.fillAvailableSpace)
          Expanded(child: _buildChart(selectedX))
        else
          SizedBox(height: 280, child: _buildChart(selectedX)),
        const SizedBox(height: 6),
        _buildZoneLegend(),
        SizedBox(height: widget.fillAvailableSpace ? 4 : 10),
        _buildRangeSelector(),
        if (!widget.fillAvailableSpace) ...[
          const SizedBox(height: 18),
          const Text(
            '양끝 손잡이로 기간을 조절하고 선택 영역을 좌우로 이동하세요. '
            '차트를 터치하면 해당 날짜의 값을 확인할 수 있습니다.',
            style: TextStyle(fontSize: 12, color: _secondaryTextColor),
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(MvrvHistoryPointModel? selected) {
    final dateLabel = _selectedIndex != null
        ? '선택 날짜'
        : _viewEndDay == _maxX.round()
        ? '최근 데이터'
        : '기간 내 마지막';
    final dateText = selected == null
        ? '선택 기간에 데이터가 없습니다.'
        : '$dateLabel · ${_dateFormat.format(selected.date)}';
    final dateSelector = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(dateText, style: const TextStyle(fontSize: 12, color: _secondaryTextColor)),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: '표시 기간의 길이를 유지하며 최근 데이터로 이동',
          child: TextButton(
            onPressed: _isAtLatest ? null : _goToLatest,
            style: TextButton.styleFrom(
              foregroundColor: _priceColor,
              disabledForegroundColor: _secondaryTextColor,
              minimumSize: const Size(64, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('최근으로'),
          ),
        ),
      ],
    );

    if (widget.fillAvailableSpace) {
      return Row(
        children: [
          Expanded(flex: 4, child: dateSelector),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildValue(
              label: 'BTC 가격',
              value: selected == null ? '—' : '\$${_priceFormat.format(selected.btcPriceUsd)}',
              color: _priceColor,
              compact: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildValue(
              label: 'MVRV Z-Score',
              value: selected?.mvrvZScore.toStringAsFixed(3) ?? '—',
              color: _mvrvColor,
              compact: true,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dateSelector,
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _buildValue(
              label: 'BTC 가격',
              value: selected == null ? '—' : '\$${_priceFormat.format(selected.btcPriceUsd)}',
              color: _priceColor,
            ),
            _buildValue(
              label: 'MVRV Z-Score',
              value: selected?.mvrvZScore.toStringAsFixed(3) ?? '—',
              color: _mvrvColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoneLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _zoneLegendItem(
          color: _bottomZoneColor,
          label:
              'Z 저점 참고 ${_bottomZoneMin.toStringAsFixed(1)}~${_bottomZoneMax.toStringAsFixed(1)}',
        ),
        _zoneLegendItem(
          color: _topZoneColor,
          label: 'Z 고점 참고 ${_topZoneMin.toStringAsFixed(0)}~${_topZoneMax.toStringAsFixed(0)}',
        ),
      ],
    );
  }

  Widget _zoneLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _secondaryTextColor)),
      ],
    );
  }

  HorizontalLine _zoneBoundary(double zScore, Color color) {
    return HorizontalLine(
      y: _zToY(zScore),
      color: color.withValues(alpha: 0.35),
      strokeWidth: 0.8,
      dashArray: [4, 4],
    );
  }

  Widget _buildValue({
    required String label,
    required String value,
    required Color color,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _secondaryTextColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: compact ? 18 : 22, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildChart(double? selectedX) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final priceTickStep =
            ((_priceLogMax - _priceLogMin) / (constraints.maxHeight < 240 ? 3 : 5)).ceilToDouble();
        final span = (_viewEndDay - _viewStartDay).toDouble();
        final dateDivisions = math.min(constraints.maxWidth >= 600 ? 6 : 3, span);
        final axisDateFormat = span <= 120 ? _shortAxisDateFormat : _axisDateFormat;

        return LineChart(
          LineChartData(
            minX: _viewStartDay.toDouble(),
            maxX: _viewEndDay.toDouble(),
            baselineX: _viewStartDay.toDouble(),
            // 0~1은 그림을 그리기 위한 좌표이며 지표 점수가 아닙니다.
            minY: 0,
            maxY: 1,
            clipData: const FlClipData.all(),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1 / (_zMax - _zMin),
              checkToShowHorizontalLine: _isZTick,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: Color(0xFFE8EDF3), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  interval: priceTickStep / (_priceLogMax - _priceLogMin),
                  getTitlesWidget: (value, meta) {
                    final logPrice = _priceLogMin + value * (_priceLogMax - _priceLogMin);
                    final price = math.pow(10, logPrice).toDouble();
                    return _axisTitle(_formatAxisPrice(price), meta, _priceColor);
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: 1 / (_zMax - _zMin),
                  minIncluded: false,
                  maxIncluded: false,
                  getTitlesWidget: (value, meta) {
                    if (!_isZTick(value)) {
                      return const SizedBox.shrink();
                    }
                    final zScore = _yToZ(value);
                    final rounded = zScore.abs() < 0.000001 ? 0.0 : zScore;
                    return _axisTitle(
                      rounded.toStringAsFixed(_zTickStep < 1 ? 1 : 0),
                      meta,
                      _mvrvColor,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: span / dateDivisions,
                  getTitlesWidget: (value, meta) {
                    final date = _points.first.date.add(Duration(days: value.round()));
                    return _axisTitle(axisDateFormat.format(date), meta, _secondaryTextColor);
                  },
                ),
              ),
            ),
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                  y1: _zToY(_bottomZoneMin),
                  y2: _zToY(_bottomZoneMax),
                  color: _bottomZoneColor.withValues(alpha: 0.08),
                ),
                HorizontalRangeAnnotation(
                  y1: _zToY(_topZoneMin),
                  y2: _zToY(_topZoneMax),
                  color: _topZoneColor.withValues(alpha: 0.08),
                ),
              ],
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                _zoneBoundary(_topZoneMin, _topZoneColor),
                _zoneBoundary(_topZoneMax, _topZoneColor),
              ],
              verticalLines: [
                if (selectedX != null)
                  VerticalLine(
                    x: selectedX,
                    color: _textColor.withValues(alpha: 0.45),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
              ],
            ),
            lineBarsData: [_line(_priceSpots, _priceColor), _line(_mvrvSpots, _mvrvColor)],
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions) {
                  return;
                }
                final spots = response?.lineBarSpots;
                if (spots == null || spots.isEmpty) {
                  return;
                }
                // 변환된 Y좌표 대신 선택 날짜에 해당하는 원본 값을 표시합니다.
                _selectDay(spots.first.x);
              },
            ),
          ),
          duration: Duration.zero,
        );
      },
    );
  }

  Widget _axisTitle(String label, TitleMeta meta, Color color) {
    return SideTitleWidget(
      meta: meta,
      space: 6,
      fitInside: SideTitleFitInsideData(
        enabled: true,
        axisPosition: meta.axisPosition,
        parentAxisSize: meta.parentAxisSize,
        distanceFromEdge: 0,
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 1.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  String _formatAxisPrice(double price) {
    if (price >= 999999.9) {
      return '\$${(price / 1000000).toStringAsFixed(0)}M';
    }
    if (price >= 999.9999) {
      return '\$${(price / 1000).toStringAsFixed(0)}K';
    }
    if (price >= 0.999999) {
      return '\$${price.toStringAsFixed(0)}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }
}
