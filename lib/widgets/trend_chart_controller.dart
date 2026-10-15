import 'dart:math' as math;
import 'package:btc_horizon/models/trend_price_cursor.dart';
import 'package:btc_horizon/models/trend_candle_model.dart';
import 'package:btc_horizon/widgets/trend_candle_painter.dart';
import 'package:btc_horizon/widgets/trend_chart_style.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

/// 캔들 인덱스의 소수 부분까지 유지하여 손가락 이동을 그대로 표시합니다.
/// 정수 start/end는 그릴 봉을 찾는 용도로만 사용합니다.
class TrendChartController extends ChangeNotifier {
  List<TrendCandle> _candles = [];
  double viewStart = 0, viewCount = 60;
  static const _rightSpace = 0.07;
  int? selected;
  bool magnetEnabled = true;
  TrendPriceCursor? priceCursor;
  static const magnetRadius = 18.0;
  void toggleMagnet() {
    magnetEnabled = !magnetEnabled;
    // 전환 후에는 다음 터치 위치에서 새 모드로 선택합니다.
    clearSelection();
  }

  bool logarithmic = false, showRsi = true, showMacd = false;
  bool priceMaximized = false;
  Set<TrendLine> visibleLines = {TrendLine.baseline, TrendLine.upper};
  TrendPriceRange? priceRange;
  double _gestureCount = 0, _gestureAnchor = 0, _scaleBase = 1;
  int _pointers = 0;
  TrendPriceRange? _gesturePrice;
  double _gestureY = 0, _gestureHeight = 1;
  bool _pricePanning = false;
  double? _timeInitial;
  double _timeX = 0, _timeRight = 0;
  TrendPriceRange? _axisInitial;
  double _axisY = 0, _axisAutoSpan = 1, _axisAnchor = 0, _axisFraction = 0.5;
  int get start => viewStart.floor().clamp(0, math.max(0, _candles.length - 1));
  int get end => (viewStart + viewCount - 1e-8).floor().clamp(0, math.max(0, _candles.length - 1));
  int get active => (selected ?? end).clamp(start, end);
  bool get inspecting => selected != null || priceCursor != null;
  bool get hasVisibleCandles =>
      _candles.isNotEmpty && viewStart < _candles.length && viewStart + viewCount > 0;
  double get _maxCount => math.max(1, _candles.length / (1 - _rightSpace));
  double _latestStart(double count) => math.max(0, _candles.length - count * (1 - _rightSpace));

  // Provider 갱신에 따른 build 안에서는 별도 알림 없이 데이터만 맞춥니다.
  void sync(List<TrendCandle> candles) {
    if (candles.isEmpty || identical(_candles, candles)) {
      return;
    }
    if (_candles.isEmpty) {
      _candles = candles;
      _recent(60 / (1 - _rightSpace));
      return;
    }
    final sameDates =
        _candles.length == candles.length &&
        _candles.first.openTime == candles.first.openTime &&
        _candles.last.openTime == candles.last.openTime;
    if (sameDates) {
      _candles = candles;
      if (priceCursor?.snapPoint case final point?) {
        if (selected != null) {
          priceCursor = TrendPriceCursor(
            index: selected!.toDouble(),
            price: point.value(_candles[selected!]),
            snapPoint: point,
          );
        }
      }
      return; // 실시간 틱이 소수 위치나 진행 중인 제스처를 반올림하지 않습니다.
    }
    final followsLatest = (viewStart - _latestStart(viewCount)).abs() < 0.001;
    final showsAll = viewStart.abs() < 0.001 && (viewCount - _maxCount).abs() < 0.001;
    final first = _candles.first.openTime;
    final selectedDate = selected == null ? null : _candles[selected!].openTime;
    _candles = candles;
    final shift = candles.first.openTime.difference(first).inDays / 7;
    viewCount = (showsAll ? _maxCount : viewCount).clamp(math.min(8, _maxCount), _maxCount);
    viewStart = followsLatest ? _latestStart(viewCount) : math.max(0.0, viewStart - shift);
    final index = selectedDate == null
        ? -1
        : _candles.indexWhere((c) => c.openTime == selectedDate);
    selected = index >= start && index <= end ? index : null;
    if (priceCursor case final cursor?) {
      final shifted = cursor.index - shift;
      priceCursor = shifted + 0.5 >= viewStart && shifted + 0.5 < viewStart + viewCount
          ? TrendPriceCursor(
              index: shifted,
              price: cursor.snapPoint != null && selected != null
                  ? cursor.snapPoint!.value(_candles[selected!])
                  : cursor.price,
              snapPoint: cursor.snapPoint,
            )
          : null;
      if (priceCursor == null) selected = null;
    }
  }

  void _recent(double count) {
    viewCount = count.clamp(math.min(8, _maxCount), _maxCount);
    viewStart = _latestStart(viewCount);
    selected = null;
    priceCursor = null;
  }

  void latest() {
    if (_candles.isEmpty) {
      return;
    }
    _recent(viewCount);
    if (priceRange case final range?) {
      final close = _candles.last.close;
      priceRange = _around(logarithmic ? math.log(close) / math.ln10 : close, range.span);
    }
    notifyListeners();
  }

  void all() {
    if (_candles.isEmpty) {
      return;
    }
    _recent(_maxCount);
    priceRange = null;
    notifyListeners();
  }

  void resetTimeScale() {
    if (_candles.isEmpty) {
      return;
    }
    _recent(60 / (1 - _rightSpace));
    notifyListeners();
  }

  void clearSelection() {
    selected = null;
    priceCursor = null;
    notifyListeners();
  }

  void setLogarithmic(bool value) {
    logarithmic = value;
    priceRange = null;
    _axisInitial = null;
    notifyListeners();
  }

  // 지표 표시 설정과 조회 위치는 그대로 두고 가격 패널만 일시적으로 확장합니다.
  void togglePriceMaximized() {
    priceMaximized = !priceMaximized;
    notifyListeners();
  }

  void setRsi(bool value) {
    showRsi = value;
    notifyListeners();
  }

  void setMacd(bool value) {
    showMacd = value;
    notifyListeners();
  }

  void toggleLine(TrendLine line, bool value) {
    if (line == TrendLine.baseline) {
      return;
    }
    visibleLines = {...visibleLines};
    if (value) {
      visibleLines.add(line);
    } else {
      visibleLines.remove(line);
    }
    notifyListeners();
  }

  double _fraction(double dx, double width) =>
      ((dx - TrendCandlePainter.leftInset) /
              math.max(1, width - TrendCandlePainter.leftInset - TrendCandlePainter.rightInset))
          .clamp(0.0, 1.0);
  void selectAt(double dx, double width) {
    priceCursor = null;
    final index = (viewStart + _fraction(dx, width) * viewCount).floor();
    // 빈 미래 구간을 선택해도 마지막 실제 봉으로 붙이지 않습니다.
    selected = index >= 0 && index < _candles.length ? index : null;
    notifyListeners();
  }

  void selectPriceAt(
    Offset local,
    double width, {
    required double plotHeight,
    required double topPadding,
    required TrendPriceRange automatic,
  }) {
    if (_candles.isEmpty || plotHeight <= 0) return;
    final plotWidth = width - TrendCandlePainter.leftInset - TrendCandlePainter.rightInset;
    if (plotWidth <= 0 ||
        local.dx < TrendCandlePainter.leftInset ||
        local.dx > width - TrendCandlePainter.rightInset ||
        local.dy < topPadding ||
        local.dy > topPadding + plotHeight) {
      return;
    }

    final range = priceRange ?? automatic;
    if (!range.span.isFinite || range.span <= 0) return;
    final index =
        viewStart + (local.dx - TrendCandlePainter.leftInset) / plotWidth * viewCount - 0.5;
    final axisValue = range.maximum - (local.dy - topPadding) / plotHeight * range.span;
    final rawPrice = logarithmic ? math.pow(10, axisValue).toDouble() : axisValue;
    if (!rawPrice.isFinite) return;
    var cursor = TrendPriceCursor(index: index, price: rawPrice);
    var candleIndex = (index + 0.5).floor();
    if (magnetEnabled) {
      final slot = plotWidth / viewCount;
      final radiusInBars = magnetRadius / slot;
      final first = math.max(0, (index - radiusInBars).ceil());
      final last = math.min(_candles.length - 1, (index + radiusInBars).floor());
      var bestDistance = magnetRadius * magnetRadius;
      for (var i = first; i <= last; i++) {
        final px = TrendCandlePainter.leftInset + (i - viewStart + 0.5) * slot;
        if (px < TrendCandlePainter.leftInset || px > width - TrendCandlePainter.rightInset) {
          continue;
        }
        for (final point in TrendSnapPoint.values) {
          final price = point.value(_candles[i]);
          final axis = logarithmic ? math.log(price) / math.ln10 : price;
          final py = topPadding + (range.maximum - axis) / range.span * plotHeight;
          if (py < topPadding || py > topPadding + plotHeight) continue;
          final distance = math.pow(px - local.dx, 2) + math.pow(py - local.dy, 2);
          if (distance < bestDistance) {
            bestDistance = distance.toDouble();
            candleIndex = i;
            cursor = TrendPriceCursor(index: i.toDouble(), price: price, snapPoint: point);
          }
        }
      }
    }
    selected = candleIndex >= 0 && candleIndex < _candles.length ? candleIndex : null;
    priceCursor = cursor;
    notifyListeners();
  }

  void _setViewport(double left, double count) {
    if (!left.isFinite || !count.isFinite || _candles.isEmpty) {
      return;
    }
    final span = count.clamp(math.min(8, _maxCount), _maxCount).toDouble();
    // 오른쪽 빈 공간은 최신 봉 위치와 별개로 자유롭게 이동합니다.
    // 왼쪽은 조회한 첫 주봉까지만 이동합니다.
    final next = math.max(0.0, left);
    if ((next - viewStart).abs() < 1e-8 && (span - viewCount).abs() < 1e-8) {
      return;
    }
    viewStart = next;
    viewCount = span;
    if (priceCursor case final cursor?) {
      if (cursor.index + 0.5 < viewStart || cursor.index + 0.5 >= viewStart + viewCount) {
        priceCursor = null;
        selected = null;
      }
    }
    if (selected != null && (selected! < viewStart.floor() || selected! >= viewStart + viewCount)) {
      selected = null;
      priceCursor = null;
    }
    notifyListeners();
  }

  void startGesture(
    ScaleStartDetails details,
    double width, {
    double? plotHeight,
    TrendPriceRange? automaticPriceRange,
  }) {
    _gestureCount = viewCount;
    _gestureAnchor = viewStart + _fraction(details.localFocalPoint.dx, width) * viewCount;
    _scaleBase = 1;
    _pointers = details.pointerCount;
    _gesturePrice = automaticPriceRange == null ? null : priceRange ?? automaticPriceRange;
    _gestureHeight = math.max(1, plotHeight ?? 1);
    _gestureY = details.localFocalPoint.dy;
    _pricePanning = false;
  }

  void updateGesture(ScaleUpdateDetails details, double width) {
    if (_gestureCount == 0 || !details.scale.isFinite || details.scale <= 0) {
      return;
    }
    final f = _fraction(details.localFocalPoint.dx, width);
    if (details.pointerCount != _pointers) {
      _pointers = details.pointerCount;
      _gestureCount = viewCount;
      _gestureAnchor = viewStart + f * viewCount;
      _scaleBase = details.scale;
      _gesturePrice = priceRange ?? _gesturePrice;
      _gestureY = details.localFocalPoint.dy;
      _pricePanning = false;
      return; // 핀치 중 손가락 수가 바뀔 때 화면이 튀지 않도록 재기준화
    }
    final count = (_gestureCount * _scaleBase / details.scale).clamp(
      math.min(8, _maxCount),
      _maxCount,
    );
    // 가격 패널의 한 손가락 드래그만 세로 범위를 이동합니다.
    // 핀치는 날짜 배율만 바꾸며 가격 배율은 가격축에서 독립적으로 조절합니다.
    var priceChanged = false;
    if (_pointers == 1 && _gesturePrice != null) {
      final range = _gesturePrice!;
      final delta = details.localFocalPoint.dy - _gestureY;
      _pricePanning = _pricePanning || delta.abs() > 6;
      if (_pricePanning) {
        final center = (range.minimum + range.maximum) / 2 + delta / _gestureHeight * range.span;
        if (center.isFinite) {
          priceRange = _around(center, range.span);
          priceChanged = true;
        }
      }
    }
    _setViewport(_gestureAnchor - f * count, count.toDouble());
    if (priceChanged) notifyListeners();
  }

  void endGesture() {
    _gestureCount = 0;
    _gesturePrice = null;
    _pricePanning = false;
  }

  // 날짜 축을 왼쪽으로 당기면 확대, 오른쪽으로 당기면 축소.
  // 현재 오른쪽 경계를 고정하여 최신/과거 위치를 쉽게 유지합니다.
  void startTimeScale(double dx) {
    _timeInitial = viewCount;
    _timeRight = viewStart + viewCount;
    _timeX = dx;
  }

  void updateTimeScale(double dx) {
    if (_timeInitial == null) {
      return;
    }
    final count = (_timeInitial! * math.exp(((dx - _timeX) / 180).clamp(-4, 4))).clamp(
      math.min(8, _maxCount),
      _maxCount,
    );
    _setViewport(_timeRight - count, count.toDouble());
  }

  void endTimeScale() => _timeInitial = null;

  /// 휠 위(음수)는 확대, 아래(양수)는 과거 구간을 더 넓게 표시합니다.
  /// 최신 구간은 최신 봉의 여백을 유지하고, 과거 구간은 오른쪽 경계를 고정합니다.
  void scrollTimeScale(double deltaY) {
    if (_candles.isEmpty || !deltaY.isFinite || deltaY == 0) return;
    final followsLatest = (viewStart - _latestStart(viewCount)).abs() < 0.001;
    final right = viewStart + viewCount;
    final count = (viewCount * math.exp((deltaY / 400).clamp(-2.0, 2.0)))
        .clamp(math.min(8, _maxCount), _maxCount)
        .toDouble();
    _setViewport(followsLatest ? _latestStart(count) : right - count, count);
  }

  TrendPriceRange _around(double center, double span) {
    final min = logarithmic ? center - span / 2 : math.max(0.0, center - span / 2);
    return TrendPriceRange(min, min + span);
  }

  void startPriceScale(double localY, double plotHeight, TrendPriceRange automatic) {
    _axisInitial = priceRange ?? automatic;
    _axisAutoSpan = automatic.span;
    _axisY = localY;
    _axisFraction = (1 - (localY - TrendCandlePainter.topInset) / math.max(1, plotHeight)).clamp(
      0.0,
      1.0,
    );
    _axisAnchor = _axisInitial!.minimum + _axisInitial!.span * _axisFraction;
  }

  void updatePriceScale(double localY) {
    if (_axisInitial == null) {
      return;
    }
    final span = (_axisInitial!.span * math.exp(((localY - _axisY) / 160).clamp(-4, 4))).clamp(
      _axisAutoSpan / 20,
      _axisAutoSpan * 20,
    );
    priceRange = _around(_axisAnchor + (0.5 - _axisFraction) * span, span);
    notifyListeners();
  }

  void endPriceScale() => _axisInitial = null;
  void autoPriceScale() {
    priceRange = null;
    notifyListeners();
  }
}
