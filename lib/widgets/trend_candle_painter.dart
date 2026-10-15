import 'dart:math' as math;
import 'package:btc_horizon/models/trend_price_cursor.dart';
import 'package:btc_horizon/models/trend_candle_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:btc_horizon/utils/trend_candle_calculator.dart';
import 'package:btc_horizon/widgets/trend_chart_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

enum TrendPane { price, rsi, macd }

/// 가격축 표시 범위. 로그 축에서는 log10으로 변환한 좌표값을 보관합니다.
class TrendPriceRange {
  final double minimum, maximum;
  const TrendPriceRange(this.minimum, this.maximum);
  double get span => maximum - minimum;
}

class TrendCandlePainter extends CustomPainter {
  final TrendCandleSeries series;
  final TrendChartDataModel? lines;
  final Set<TrendLine> visibleLines;
  final int start, end, selected;
  final double? viewStart, viewCount;
  final bool showSelection;
  final TrendPane pane;
  final bool logarithmic;
  final bool showDateAxis;
  final bool compact;
  final TrendPriceRange? priceRange;
  final double? livePrice;
  final TrendPriceCursor? priceCursor;
  final double fontSize;
  final double topPadding;
  TrendCandlePainter({
    required this.series,
    required this.lines,
    required this.visibleLines,
    required this.start,
    required this.end,
    required this.selected,
    required this.pane,
    required this.logarithmic,
    this.viewStart,
    this.viewCount,
    this.showSelection = true,
    this.showDateAxis = true,
    this.compact = false,
    this.priceRange,
    this.livePrice,
    this.priceCursor,
    this.fontSize = 10,
    this.topPadding = topInset,
  });

  static const leftInset = 8.0;
  static const rightInset = 55.0;
  static const topInset = 12.0;

  // 날짜가 없는 패널도 세로축의 끝 눈금이 잘리지 않을 여백은 남깁니다.
  double get bottomInset =>
      showDateAxis ? math.max(compact ? 30.0 : 44.0, fontSize * 1.5 + 12) : fontSize / 2 + 3;

  /// 실제 기록 밖의 날짜는 주봉 간격으로 표시하며 가격을 생성하지 않습니다.
  DateTime dateAtIndex(int index) {
    if (index >= 0 && index < series.candles.length) {
      return series.candles[index].openTime;
    }
    final anchor = index < 0 ? series.candles.first : series.candles.last;
    final offset = index < 0 ? index : index - (series.candles.length - 1);
    return anchor.openTime.toUtc().add(Duration(days: 7 * offset));
  }

  bool get hasVisibleCandles =>
      (viewStart ?? start.toDouble()) < series.candles.length &&
      (viewStart ?? start.toDouble()) + (viewCount ?? end - start + 1) > 0;

  TrendPriceRange get automaticPriceRange {
    // 미래만 보일 때는 최근 60봉으로 축만 유지합니다. 미래 가격은 그리지 않습니다.
    final rangeStart = hasVisibleCandles ? start : math.max(0, series.candles.length - 60);
    final rangeEnd = hasVisibleCandles ? end : series.candles.length - 1;
    final values = <double>[
      for (var i = rangeStart; i <= rangeEnd; i++) ...[
        series.candles[i].low,
        series.candles[i].high,
      ],
      if (lines != null)
        for (final line in visibleLines)
          for (var i = rangeStart; i <= rangeEnd; i++)
            if (trendValueAt(line.points(lines!), series.candles[i].openTime)
                case final double value)
              value,
    ].map((value) => logarithmic ? math.log(value) / math.ln10 : value);
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final padding = math.max(
      (maximum - minimum) * 0.08,
      logarithmic ? 0.005 : maximum.abs() * 0.005,
    );
    return TrendPriceRange(
      logarithmic ? minimum - padding : math.max(0.0, minimum - padding),
      maximum + padding,
    );
  }

  /// 패널 크기는 유지하며 보이는 RSI와 30·70 기준선에 세로축을 맞춥니다.
  ({double minimum, double maximum}) get automaticRsiRange {
    var minimum = 30.0, maximum = 70.0;
    if (hasVisibleCandles) {
      final values = series.oscillators.rsi;
      for (var i = math.max(0, start); i <= math.min(end, values.length - 1); i++) {
        final value = values[i];
        if (value == null || !value.isFinite) continue;
        minimum = math.min(minimum, value);
        maximum = math.max(maximum, value);
      }
    }
    final padding = math.max(2.0, (maximum - minimum) * 0.08);
    return (minimum: math.max(0.0, minimum - padding), maximum: math.min(100.0, maximum + padding));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      leftInset,
      topPadding,
      size.width - rightInset,
      size.height - bottomInset,
    );
    if (plot.width <= 0 || plot.height <= 0) {
      return;
    }
    final count = end - start + 1;
    final slot = plot.width / (viewCount ?? count.toDouble());
    double x(num index) => plot.left + (index - (viewStart ?? start.toDouble()) + 0.5) * slot;
    final selectionIndex = priceCursor?.index ?? selected.toDouble();
    final selectionPrice =
        priceCursor?.price ??
        (selected >= 0 && selected < series.candles.length ? series.candles[selected].close : null);
    final selectionVisible =
        showSelection &&
        (priceCursor != null || (selected >= start && selected <= end)) &&
        x(selectionIndex) >= plot.left &&
        x(selectionIndex) <= plot.right;
    double convert(double v) =>
        pane == TrendPane.price && logarithmic ? math.log(v) / math.ln10 : v;
    final lineValues = <TrendLine, List<double?>>{};
    if (pane == TrendPane.price && lines != null) {
      for (final line in visibleLines) {
        lineValues[line] = [
          for (var i = start; i <= end; i++)
            trendValueAt(line.points(lines!), series.candles[i].openTime),
        ];
      }
    }
    var minimum = 0.0, maximum = 100.0;
    if (pane == TrendPane.price) {
      final range = priceRange ?? automaticPriceRange;
      minimum = range.minimum;
      maximum = range.maximum;
    } else if (pane == TrendPane.rsi) {
      final range = automaticRsiRange;
      minimum = range.minimum;
      maximum = range.maximum;
    } else if (pane == TrendPane.macd) {
      final osc = series.oscillators;
      final values = <double>[
        0,
        ...osc.macd.sublist(start, end + 1).whereType<double>(),
        ...osc.signal.sublist(start, end + 1).whereType<double>(),
        ...osc.histogram.sublist(start, end + 1).whereType<double>(),
      ];
      minimum = values.reduce(math.min);
      maximum = values.reduce(math.max);
      final padding = math.max((maximum - minimum) * 0.12, 0.001);
      minimum -= padding;
      maximum += padding;
    }
    double y(double v) => plot.bottom - (convert(v) - minimum) / (maximum - minimum) * plot.height;
    void text(String value, Offset offset, {Color color = trendMuted}) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontSize: fontSize, color: color, height: 1),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(1, size.width - offset.dx - 2));
      painter.paint(canvas, Offset(offset.dx, offset.dy - painter.height / 2));
      painter.dispose();
    }

    final grid = Paint()
      ..color = trendGrid
      ..strokeWidth = 0.8;
    final tickFormat = NumberFormat.compact(locale: 'en');
    if (pane == TrendPane.price && priceRange != null) {
      // 세로 확대 시 인접 눈금이 같은 반올림 값으로 표시되지 않도록 합니다.
      tickFormat.maximumSignificantDigits = 5;
    }
    List<double> ticks;
    if (pane == TrendPane.rsi) {
      ticks = plot.height < 55 ? [30, 70] : [30, 50, 70];
      canvas.drawRect(
        Rect.fromLTRB(plot.left, y(70), plot.right, y(30)),
        Paint()..color = const Color(0xFFF4F2FB),
      );
    } else if (pane == TrendPane.macd) {
      ticks = [minimum, 0, maximum];
    } else if (pane == TrendPane.price && !logarithmic) {
      final tickCount = (plot.height / (fontSize * 2.8)).floor().clamp(2, 5);
      final rough = (maximum - minimum) / tickCount;
      final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
      final fraction = rough / magnitude;
      final factor = <double>[
        1,
        2,
        2.5,
        5,
        10,
      ].reduce((a, b) => (a - fraction).abs() <= (b - fraction).abs() ? a : b);
      final step = factor * magnitude;
      ticks = [
        for (var tick = (minimum / step).ceil() * step; tick <= maximum + step * 1e-8; tick += step)
          tick,
      ];
    } else {
      ticks = [for (var i = 0; i <= 3; i++) minimum + (maximum - minimum) * i / 3];
    }
    double? liveAxisY;
    if (pane == TrendPane.price &&
        livePrice != null &&
        end == series.candles.length - 1 &&
        plot.height > fontSize + 8) {
      final liveY = y(livePrice!);
      if (liveY >= plot.top && liveY <= plot.bottom) {
        liveAxisY = liveY.clamp(plot.top + fontSize / 2 + 4, plot.bottom - fontSize / 2 - 4);
      }
    }
    double? selectedAxisY;
    if (pane == TrendPane.price &&
        selectionVisible &&
        selectionPrice != null &&
        plot.height > fontSize + 8) {
      final selectedY = y(selectionPrice);
      if (selectedY.isFinite && selectedY >= plot.top && selectedY <= plot.bottom) {
        selectedAxisY = selectedY.clamp(
          plot.top + fontSize / 2 + 4,
          plot.bottom - fontSize / 2 - 4,
        );
      }
    }
    // 라벨이 겹치면 사용자가 확인 중인 봉의 가격을 우선합니다.
    if (selectedAxisY != null &&
        liveAxisY != null &&
        (selectedAxisY - liveAxisY).abs() < fontSize + 10) {
      liveAxisY = null;
    }
    for (final tick in ticks) {
      final raw = pane == TrendPane.price && logarithmic ? math.pow(10, tick).toDouble() : tick;
      final top = y(raw);
      //canvas.drawLine(Offset(plot.left, top), Offset(plot.right, top), grid);
      final linePaint = pane == TrendPane.rsi
          ? (Paint()
              ..color = tick == 50
                  ? const Color(0xFF768397) // 중단선: 진한 회청색
                  : const Color(0xFF9AA6B6) // 30·70선: 부드러운 회청색
              ..strokeWidth = tick == 50 ? 1.1 : 1.0)
          : grid;

      canvas.drawLine(Offset(plot.left, top), Offset(plot.right, top), linePaint);
      if (pane == TrendPane.macd && tick != 0 && (top - y(0)).abs() < fontSize + 4) {
        continue;
      }
      if (liveAxisY != null && (top - liveAxisY).abs() < fontSize + 7) continue;
      if (selectedAxisY != null && (top - selectedAxisY).abs() < fontSize + 7) continue;
      text(
        pane == TrendPane.rsi ? tick.toInt().toString() : tickFormat.format(raw),
        Offset(plot.right + 7, top),
      );
    }
    canvas.save();
    canvas.clipRect(plot);
    if (pane == TrendPane.price) {
      final bodyWidth = math.max(0.45, math.min(12.0, slot * 0.65));
      // 가격축과 독립적인 선형 거래량 스케일. 캔들 뒤, 하단 20%에만 그립니다.
      // 화면에 실제 봉이 없거나 모두 0/null인 경우 막대를 그리지 않습니다.
      if (hasVisibleCandles) {
        var maxVolume = 0.0;
        for (var i = start; i <= end; i++) {
          final volume = series.candles[i].volume;
          if (volume != null && volume.isFinite && volume > maxVolume) {
            maxVolume = volume;
          }
        }
        if (maxVolume > 0) {
          for (var i = start; i <= end; i++) {
            final candle = series.candles[i];
            final volume = candle.volume;
            if (volume == null || !volume.isFinite || volume <= 0) continue;
            final height = volume / maxVolume * plot.height * 0.20;
            canvas.drawRect(
              Rect.fromLTWH(x(i) - bodyWidth / 2, plot.bottom - height, bodyWidth, height),
              Paint()
                ..color = (candle.close >= candle.open ? trendUp : trendDown).withValues(
                  alpha: 0.22,
                ),
            );
          }
        }
      }
      for (var i = start; i <= end; i++) {
        final c = series.candles[i];
        final paint = Paint()
          ..color = (c.close >= c.open ? trendUp : trendDown)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(x(i), y(c.high)), Offset(x(i), y(c.low)), paint);
        final top = math.min(y(c.open), y(c.close));
        final bottom = math.max(y(c.open), y(c.close));
        canvas.drawRect(
          Rect.fromLTWH(x(i) - bodyWidth / 2, top, bodyWidth, math.max(1, bottom - top)),
          paint,
        );
      }
      for (final entry in lineValues.entries) {
        final path = Path();
        var started = false;
        for (var j = 0; j < entry.value.length; j++) {
          final value = entry.value[j];
          if (value == null) {
            started = false;
            continue;
          }
          final dx = x(start + j), dy = y(value);
          if (!started) {
            path.moveTo(dx, dy);
            started = true;
          } else {
            path.lineTo(dx, dy);
          }
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = entry.key.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = entry.key.strokeWidth,
        );
      }
    } else {
      final osc = series.oscillators;
      void drawSeries(List<double?> values, Color color) {
        final path = Path();
        var started = false;
        for (var i = start; i <= end; i++) {
          final value = values[i];
          if (value == null) {
            started = false;
            continue;
          }
          if (!started) {
            path.moveTo(x(i), y(value));
            started = true;
          } else {
            path.lineTo(x(i), y(value));
          }
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
        );
      }

      if (pane == TrendPane.rsi) {
        drawSeries(osc.rsi, const Color(0xFF7962C5));
      } else {
        canvas.drawLine(
          Offset(plot.left, y(0)),
          Offset(plot.right, y(0)),
          Paint()
            ..color = const Color(0xFFBCC3CF)
            ..strokeWidth = 0.8,
        );
        for (var i = start; i <= end; i++) {
          final v = osc.histogram[i];
          if (v == null) {
            continue;
          }
          canvas.drawRect(
            Rect.fromLTWH(
              x(i) - slot * 0.3,
              math.min(y(0), y(v)),
              math.max(1, slot * 0.6),
              math.max(0.8, (y(v) - y(0)).abs()),
            ),
            Paint()..color = (v >= 0 ? trendUp : trendDown).withValues(alpha: 0.45),
          );
        }
        drawSeries(osc.macd, const Color(0xFF168CAF));
        drawSeries(osc.signal, const Color(0xFFBC7900));
      }
    }
    if (pane == TrendPane.price && livePrice != null && end == series.candles.length - 1) {
      final top = y(livePrice!);
      if (top >= plot.top && top <= plot.bottom) {
        final livePaint = Paint()
          ..color = (livePrice! >= series.candles.last.open ? trendUp : trendDown).withValues(
            alpha: 0.6,
          )
          ..strokeWidth = 0.8;
        for (var left = plot.left; left < plot.right; left += 7) {
          canvas.drawLine(
            Offset(left, top),
            Offset(math.min(left + 3, plot.right), top),
            livePaint,
          );
        }
      }
    }
    if (selectionVisible) {
      final guide = Paint()
        ..color = const Color(0xFF718096)
        ..strokeWidth = 1;
      for (var top = plot.top; top < plot.bottom; top += 7) {
        canvas.drawLine(
          Offset(x(selectionIndex), top),
          Offset(x(selectionIndex), math.min(top + 3, plot.bottom)),
          guide,
        );
      }
      if (pane == TrendPane.price) {
        final top = y(selectionPrice!);
        for (var left = plot.left; left < plot.right; left += 7) {
          canvas.drawLine(Offset(left, top), Offset(math.min(left + 3, plot.right), top), guide);
        }
        if (priceCursor == null || priceCursor!.snapPoint != null) {
          canvas.drawCircle(Offset(x(selectionIndex), top), 3, Paint()..color = trendInk);
        }
      }
    }
    canvas.restore();
    void drawPriceLabel(double price, double axisY, Color color) {
      final label = TextPainter(
        text: TextSpan(
          text: NumberFormat('#,##0.00').format(price),
          style: TextStyle(fontSize: fontSize, height: 1, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      // 55px 가격축에서도 K 단위로 축약하지 않고 소수 둘째 자리까지 표시합니다.
      final availableWidth = math.max(1.0, rightInset - 13);
      final scale = label.width > availableWidth ? availableWidth / label.width : 1.0;
      final height = label.height * scale + 8;
      final rect = Rect.fromLTWH(
        plot.right + 3,
        (axisY - height / 2).clamp(plot.top, plot.bottom - height),
        rightInset - 5,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = color,
      );
      canvas.save();
      canvas.translate(rect.left + 4, rect.top + 4);
      canvas.scale(scale);
      label.paint(canvas, Offset.zero);
      canvas.restore();
      label.dispose();
    }

    if (liveAxisY != null) {
      drawPriceLabel(
        livePrice!,
        liveAxisY,
        livePrice! >= series.candles.last.open ? trendUp : trendDown,
      );
    }
    if (selectedAxisY != null) {
      drawPriceLabel(selectionPrice!, selectedAxisY, trendInk);
    }
    if (!showDateAxis) {
      return;
    }
    canvas.drawRect(
      Rect.fromLTRB(0, plot.bottom + fontSize / 2 + 3, size.width, size.height),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    text('↔', Offset(plot.right + 12, plot.bottom + 18));
    // 눈금은 실제 봉 목록이 아닌 현재 화면 범위를 기준으로 배치합니다.
    final firstIndex = (viewStart ?? start.toDouble()).ceil();
    final lastIndex = math.max(
      firstIndex,
      ((viewStart ?? start.toDouble()) + (viewCount ?? count.toDouble()) - 1).floor(),
    );
    final firstDate = dateAtIndex(firstIndex);
    final lastDate = dateAtIndex(lastIndex);
    final shortRange = lastDate.difference(firstDate).inDays <= 200;
    final dateFormat = DateFormat(
      shortRange ? (firstDate.year == lastDate.year ? 'MM/dd' : 'yy/MM/dd') : 'yy.MM',
    );
    final ticksCount = plot.width < 320 ? 3 : 5;
    var previousRight = double.negativeInfinity;
    for (var t = 0; t < ticksCount; t++) {
      final index = firstIndex + ((lastIndex - firstIndex) * t / (ticksCount - 1)).round();
      final value = dateFormat.format(dateAtIndex(index));
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontSize: fontSize, color: trendMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (x(index) - painter.width / 2)
          .clamp(plot.left, math.max(plot.left, plot.right - painter.width))
          .toDouble();
      if (left >= previousRight + 8) {
        painter.paint(canvas, Offset(left, plot.bottom + 8));
        previousRight = left + painter.width;
      }
      painter.dispose();
    }
    // 교차선 날짜는 명시적으로 봉을 선택한 동안만 표시합니다.
    if (selectionVisible) {
      final label = DateFormat('yyyy/MM/dd').format(dateAtIndex((selectionIndex + 0.5).floor()));
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: fontSize, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(1, plot.width - 12));
      final left = (x(selectionIndex) - painter.width / 2 - 6)
          .clamp(plot.left, math.max(plot.left, plot.right - painter.width - 12))
          .toDouble();
      final rect = Rect.fromLTWH(left, plot.bottom + 6, painter.width + 12, painter.height + 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = trendInk,
      );
      painter.paint(canvas, rect.topLeft + const Offset(6, 4));
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant TrendCandlePainter old) =>
      series != old.series ||
      lines != old.lines ||
      visibleLines != old.visibleLines ||
      start != old.start ||
      end != old.end ||
      selected != old.selected ||
      viewStart != old.viewStart ||
      viewCount != old.viewCount ||
      showSelection != old.showSelection ||
      pane != old.pane ||
      logarithmic != old.logarithmic ||
      showDateAxis != old.showDateAxis ||
      compact != old.compact ||
      priceRange != old.priceRange ||
      livePrice != old.livePrice ||
      priceCursor != old.priceCursor ||
      topPadding != old.topPadding ||
      fontSize != old.fontSize;
}
