import 'package:btc_horizon/models/weekly_trend_market_model.dart';
import 'package:btc_horizon/providers/trend_market_data_provider.dart';
import 'package:btc_horizon/screens/trend_fullscreen_screen.dart';
import 'package:btc_horizon/widgets/trend_candle_painter.dart';
import 'package:btc_horizon/widgets/trend_chart_controller.dart';
import 'package:btc_horizon/widgets/trend_chart_gestures.dart';
import 'package:btc_horizon/widgets/trend_chart_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TrendChartSection extends StatefulWidget {
  final double? height;
  const TrendChartSection({super.key, this.height});
  @override
  State<TrendChartSection> createState() => _TrendChartSectionState();
}

class _TrendChartSectionState extends State<TrendChartSection> {
  final controller = TrendChartController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: widget.height,
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    decoration: trendCardDecoration(),
    child: TrendChartPanel(
      controller: controller,
      onExpand:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TrendFullscreenScreen(controller: controller),
            ),
          ),
    ),
  );
}

class TrendChartPanel extends ConsumerWidget {
  final TrendChartController controller;
  final bool fullscreen;
  final VoidCallback? onExpand, onClose;
  const TrendChartPanel({
    super.key,
    required this.controller,
    this.fullscreen = false,
    this.onExpand,
    this.onClose,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(trendMarketProvider);
    void refresh() =>
        ref.read(binanceWeeklyTrendServiceProvider).checkConnection();
    return market.when(
      loading:
          () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('주봉 데이터를 불러오지 못했습니다.'),
                TextButton(onPressed: refresh, child: const Text('다시 연결')),
                if (onClose != null)
                  TextButton(onPressed: onClose, child: const Text('확대 화면 닫기')),
              ],
            ),
          ),
      data: (data) {
        controller.sync(data.series.candles);
        return AnimatedBuilder(
          animation: controller,
          builder:
              (context, _) => LayoutBuilder(
                builder: (context, constraints) {
                  final normalText =
                      MediaQuery.textScalerOf(context).scale(12) <= 15;
                  final compact =
                      fullscreen && constraints.maxWidth >= 760 && normalText;
                  final bounded =
                      constraints.hasBoundedHeight &&
                      normalText &&
                      constraints.maxHeight >= (compact ? 340 : 540) &&
                      constraints.maxWidth >= 320;
                  final chart = _TrendChartBody(
                    market: data,
                    controller: controller,
                    compact: compact,
                    bounded: bounded,
                    onExpand: onExpand,
                    onClose: onClose,
                    onRefresh: refresh,
                  );
                  return constraints.hasBoundedHeight && !bounded
                      ? SingleChildScrollView(child: chart)
                      : chart;
                },
              ),
        );
      },
    );
  }
}

class _TrendChartBody extends StatelessWidget {
  final WeeklyTrendMarket market;
  final TrendChartController controller;
  final bool compact, bounded;
  final VoidCallback? onExpand, onClose;
  final VoidCallback onRefresh;
  const _TrendChartBody({
    required this.market,
    required this.controller,
    required this.compact,
    required this.bounded,
    this.onExpand,
    this.onClose,
    required this.onRefresh,
  });
  String value(double? number) =>
      number == null ? '—' : NumberFormat('#,##0.00').format(number);
  String brief(double? number) =>
      number == null
          ? '—'
          : (NumberFormat.compact(locale: 'en')
            ..maximumFractionDigits = 2).format(number);
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final candles = market.series.candles;
    final active = candles[c.active];
    final latest = candles.last;
    final live = market.snapshot.isLive;
    final hasActiveCandle =
        c.hasVisibleCandles && (!c.inspecting || c.selected != null);
    final osc = market.series.oscillators;
    final showRsi = c.showRsi && !c.priceMaximized;
    final showMacd = c.showMacd && !c.priceMaximized;
    final lastPane =
        showMacd
            ? TrendPane.macd
            : showRsi
            ? TrendPane.rsi
            : TrendPane.price;
    final status = switch (market.snapshot.connection) {
      TrendConnection.live => '실시간',
      TrendConnection.connecting => '연결 중',
      TrendConnection.reconnecting => '수신 지연',
    };
    Widget icon(IconData glyph, String label, VoidCallback? action) =>
        IconButton(
          tooltip: label,
          onPressed: action,
          icon: Icon(glyph, size: 20),
          constraints: BoxConstraints(
            minWidth: compact ? 32 : 44,
            minHeight: compact ? 32 : 44,
          ),
          padding: EdgeInsets.all(compact ? 6 : 8),
        );
    Widget actions() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('trend-magnet'),
          tooltip:
              c.magnetEnabled
                  ? '자석 켜짐 · 가까운 시가·고가·저가·종가에 맞춤'
                  : '자석 꺼짐 · 자유 가격 선택',
          isSelected: c.magnetEnabled,
          onPressed: c.toggleMagnet,
          constraints: BoxConstraints(
            minWidth: compact ? 32 : 44,
            minHeight: compact ? 32 : 44,
          ),
          padding: EdgeInsets.all(compact ? 6 : 8),
          style: IconButton.styleFrom(
            backgroundColor:
                c.magnetEnabled ? const Color(0xFFE7F4F8) : Colors.transparent,
          ),
          icon: CustomPaint(
            size: const Size(20, 20),
            painter: _MagnetIconPainter(
              c.magnetEnabled ? const Color(0xFF168CAF) : trendMuted,
            ),
          ),
        ),
        if (c.priceMaximized)
          icon(Icons.splitscreen_rounded, '지표 다시 표시', c.togglePriceMaximized),
        icon(Icons.tune_rounded, '차트 설정 및 도움말', () => _settings(context)),
        if (onExpand != null) icon(Icons.fullscreen_rounded, '차트 확대', onExpand),
        if (onClose != null)
          icon(Icons.fullscreen_exit_rounded, '확대 화면 닫기', onClose),
      ],
    );
    Widget link(String label, VoidCallback action) => TextButton(
      onPressed: action,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: trendMuted,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
    Widget badge() => Tooltip(
      message:
          '마지막 수신 ${DateFormat('MM/dd HH:mm:ss').format(market.snapshot.receivedAt.toLocal())} · 기기 시간',
      child: Text(
        '● $status',
        style: TextStyle(
          fontSize: 10,
          color: live ? trendUp : const Color(0xFFAA6900),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    Widget quote() => Text(
      '${value(latest.close)} USDT',
      style: TextStyle(
        fontSize: compact ? 17 : 23,
        fontWeight: FontWeight.w700,
        color:
            live
                ? (latest.close >= latest.open ? trendUp : trendDown)
                : trendMuted,
      ),
    );
    Widget autoButton() => Tooltip(
      message: c.priceRange == null ? '가격축 자동 맞춤 사용 중' : '가격축 자동 맞춤으로 복귀',
      child: TextButton.icon(
        key: const ValueKey('trend-auto-price'),
        onPressed: c.autoPriceScale,
        icon: Icon(
          Icons.fit_screen_rounded,
          size: 16,
          color: c.priceRange == null ? const Color(0xFF168CAF) : trendMuted,
        ),
        label: Text(
          c.priceRange == null ? '자동' : '자동 맞춤',
          style: const TextStyle(fontSize: 11),
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 40),
          foregroundColor:
              c.priceRange == null ? const Color(0xFF168CAF) : trendMuted,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
    Widget volumeLegend() => Tooltip(
      message:
          'Binance BTC/USDT 주봉 거래량 · BTC 단위\n진행 중인 주봉은 누적 거래량이며 마감 전까지 변합니다.\n막대는 현재 보이는 봉 중 최대 거래량에 맞춰 표시합니다.',
      child: Text(
        '▥ 거래량 ${brief(hasActiveCandle ? active.volume : null)} BTC',
        style: const TextStyle(fontSize: 11, color: trendMuted),
      ),
    );
    Widget legend() => Wrap(
      spacing: 12,
      runSpacing: 3,
      children: [
        volumeLegend(),
        for (final line in TrendLine.values.where(c.visibleLines.contains))
          Tooltip(
            message: line.formula,
            child: Text(
              '━ ${line.label}',
              style: TextStyle(color: line.color, fontSize: 11),
            ),
          ),
      ],
    );
    Widget readout() =>
        !hasActiveCandle
            ? SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    c.priceCursor == null
                        ? '미래 구간 · 가격 데이터 없음'
                        : '자유 가격 ${value(c.priceCursor!.price)} · 해당 봉 데이터 없음',
                    style: const TextStyle(fontSize: 11, color: trendMuted),
                  ),
                ),
              ),
            )
            : Container(
              key: const ValueKey('trend-candle-readout'),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${c.inspecting
                              ? '선택'
                              : c.end == candles.length - 1
                              ? '최근'
                              : '구간 끝'} ${DateFormat('yy.MM.dd').format(active.openTime)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: trendMuted,
                          ),
                        ),
                        if (c.inspecting || c.end != candles.length - 1)
                          Text(
                            value(c.priceCursor?.price ?? active.close),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: trendInk,
                            ),
                          ),
                        Text(
                          c.priceCursor != null
                              ? (c.priceCursor!.snapPoint?.label ?? '자유 가격')
                              : (active.isClosed ? '마감' : '미확정'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: trendMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (c.inspecting)
                    icon(Icons.close_rounded, '봉 선택 해제', c.clearSelection),
                  icon(
                    Icons.info_outline_rounded,
                    '봉 상세 정보',
                    () => _candleDetails(context),
                  ),
                ],
              ),
            );
    Widget pane(TrendPane type, {double? plotHeight}) => LayoutBuilder(
      builder: (context, box) {
        final painter = TrendCandlePainter(
          series: market.series,
          lines: market.lines,
          visibleLines: c.visibleLines,
          start: c.start,
          end: c.end,
          selected: c.active,
          viewStart: c.viewStart,
          viewCount: c.viewCount,
          showSelection: c.inspecting,
          priceCursor: c.priceCursor,
          pane: type,
          logarithmic: c.logarithmic,
          showDateAxis: type == lastPane,
          compact: compact,
          priceRange: type == TrendPane.price ? c.priceRange : null,
          livePrice: live ? latest.close : null,
          fontSize: MediaQuery.textScalerOf(context).scale(10).clamp(9, 14),
          topPadding:
              compact || type != TrendPane.price
                  ? 6
                  : TrendCandlePainter.topInset,
        );
        final height =
            plotHeight == null
                ? box.maxHeight
                : plotHeight + painter.topPadding + painter.bottomInset;
        final actualPlotHeight =
            height - painter.topPadding - painter.bottomInset;
        return Semantics(
          label: '${type.name} 주봉 차트',
          hint:
              type == TrendPane.price
                  ? '상하좌우 드래그로 이동, 핀치로 기간 확대·축소, 두 번 탭으로 가격 차트 최대화 또는 복원'
                  : '좌우 드래그로 이동, 핀치로 기간 확대·축소',
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TrendChartGestures(
                  onStart:
                      (d) => c.startGesture(
                        d,
                        box.maxWidth,
                        plotHeight: actualPlotHeight,
                        automaticPriceRange:
                            type == TrendPane.price
                                ? painter.automaticPriceRange
                                : null,
                      ),
                  onUpdate: (d) => c.updateGesture(d, box.maxWidth),
                  onSelect: (p) {
                    if (type == TrendPane.price) {
                      c.selectPriceAt(
                        p,
                        box.maxWidth,
                        plotHeight: actualPlotHeight,
                        topPadding: painter.topPadding,
                        automatic: painter.automaticPriceRange,
                      );
                    } else {
                      c.selectAt(p.dx, box.maxWidth);
                    }
                  },
                  onEnd: c.endGesture,
                  onDoubleTap:
                      type == TrendPane.price ? c.togglePriceMaximized : null,
                  onScroll: c.scrollTimeScale,
                  child: RepaintBoundary(child: CustomPaint(painter: painter)),
                ),
                if (type == lastPane)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: painter.bottomInset,
                    child: Semantics(
                      label: '날짜 가로축',
                      hint: '좌우 드래그로 기간 확대·축소, 두 번 탭으로 최근 60주',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: GestureDetector(
                          key: const ValueKey('trend-time-axis'),
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart:
                              (d) => c.startTimeScale(d.localPosition.dx),
                          onHorizontalDragUpdate:
                              (d) => c.updateTimeScale(d.localPosition.dx),
                          onHorizontalDragEnd: (_) => c.endTimeScale(),
                          onHorizontalDragCancel: c.endTimeScale,
                          onDoubleTap: c.resetTimeScale,
                        ),
                      ),
                    ),
                  ),
                if (type == TrendPane.price)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: painter.bottomInset,
                    width: TrendCandlePainter.rightInset,
                    child: Semantics(
                      label: '가격 세로축',
                      hint: '위아래 드래그로 배율 조절, 두 번 탭으로 자동 맞춤',
                      child: GestureDetector(
                        key: const ValueKey('trend-price-axis'),
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart:
                            (d) => c.startPriceScale(
                              d.localPosition.dy,
                              actualPlotHeight,
                              painter.automaticPriceRange,
                            ),
                        onVerticalDragUpdate:
                            (d) => c.updatePriceScale(d.localPosition.dy),
                        onVerticalDragEnd: (_) => c.endPriceScale(),
                        onVerticalDragCancel: c.endPriceScale,
                        onDoubleTap: c.autoPriceScale,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    Widget rsiHeading() => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'RSI (14)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: trendInk,
            ),
          ),
          Text(
            value(hasActiveCandle ? osc.rsi[c.active] : null),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7962C5),
            ),
          ),
        ],
      ),
    );
    Widget macdHeading() => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 9,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Tooltip(
            message: 'MACD (12, 26, 9)',
            child: Text(
              'MACD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: trendInk,
              ),
            ),
          ),
          for (final item in [
            ('MACD', osc.macd[c.active], const Color(0xFF168CAF)),
            ('Signal', osc.signal[c.active], const Color(0xFFBC7900)),
            (
              'Hist',
              osc.histogram[c.active],
              (osc.histogram[c.active] ?? 0) >= 0 ? trendUp : trendDown,
            ),
          ])
            Tooltip(
              message: '${item.$1} ${value(hasActiveCandle ? item.$2 : null)}',
              child: Text(
                '${item.$1 == 'MACD' ? '' : '${item.$1} '}${brief(hasActiveCandle ? item.$2 : null)}',
                style: TextStyle(fontSize: 11, color: item.$3),
              ),
            ),
        ],
      ),
    );
    Widget plots() => LayoutBuilder(
      builder: (context, box) {
        // 공통 날짜축 높이는 별도로 확보하고, 남은 공간을 가격 패널에 우선 배분합니다.
        final visibleOscillators = (showRsi ? 1 : 0) + (showMacd ? 1 : 0);
        final smallHeight =
            bounded
                ? ((box.maxHeight -
                            (compact ? 30 : 44) -
                            visibleOscillators * 32) *
                        (compact ? 0.15 : 0.18))
                    .clamp(30.0, compact ? 52.0 : 85.0)
                : 75.0;
        return Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bounded)
              Expanded(child: pane(TrendPane.price))
            else
              pane(
                TrendPane.price,
                plotHeight:
                    340 +
                    (c.priceMaximized
                        ? 110.0 * ((c.showRsi ? 1 : 0) + (c.showMacd ? 1 : 0))
                        : 0),
              ),
            if (showRsi) ...[
              const Divider(height: 1, thickness: 0.7, color: trendGrid),
              rsiHeading(),
              pane(TrendPane.rsi, plotHeight: smallHeight),
            ],
            if (showMacd) ...[
              const Divider(height: 1, thickness: 0.7, color: trendGrid),
              macdHeading(),
              pane(TrendPane.macd, plotHeight: smallHeight),
            ],
          ],
        );
      },
    );
    // 이 여백에는 차트 제스처를 붙이지 않습니다. 여기서 시작하면 페이지가 스크롤됩니다.
    Widget framedPlots() => Padding(
      key: const ValueKey('trend-chart-scroll-margin'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 4,
        vertical: compact ? 2 : 12,
      ),
      child: Container(
        padding: EdgeInsets.only(right: compact ? 0 : 24),
        color: compact ? Colors.transparent : const Color(0xFFF6F7FB),
        child: DecoratedBox(
          key: const ValueKey('trend-chart-frame'),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD5DBE5), width: 1),
            borderRadius: BorderRadius.circular(compact ? 8 : 12),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 2 : 5),
            child: plots(),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact)
          Row(
            children: [
              const Text(
                'BTC/USDT · 주봉',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: trendInk,
                ),
              ),
              const SizedBox(width: 12),
              quote(),
              const SizedBox(width: 8),
              badge(),
              const Spacer(),
              link('최근으로', c.latest),
              link('전체 보기', c.all),
              autoButton(),
              actions(),
            ],
          )
        else ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BTC/USDT · 주봉',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: trendInk,
                  ),
                ),
              ),
              actions(),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [quote(), badge()],
          ),
          Wrap(
            spacing: 2,
            runSpacing: 0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              link('최근으로', c.latest),
              link('전체 보기', c.all),
              autoButton(),
            ],
          ),
        ],
        if (compact)
          Row(
            children: [
              Expanded(flex: 2, child: legend()),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: readout()),
            ],
          )
        else ...[
          readout(),
          legend(),
        ],
        const SizedBox(height: 2),
        if (bounded) Expanded(child: framedPlots()) else framedPlots(),
        if (!compact)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Binance · BTC/USDT',
              style: TextStyle(fontSize: 10, color: trendMuted),
            ),
          ),
      ],
    );
  }

  void _candleDetails(BuildContext context) {
    final date = market.series.candles[controller.active].openTime;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => Consumer(
            builder: (context, ref, _) {
              final current = ref.watch(trendMarketProvider);
              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: current.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _) => const Text('봉 정보를 불러오지 못했습니다.'),
                      data: (data) {
                        final index = data.series.candles.indexWhere(
                          (c) => c.openTime == date,
                        );
                        if (index < 0) {
                          return const Text('현재 조회 범위를 벗어난 주봉입니다.');
                        }
                        final candle = data.series.candles[index];
                        final osc = data.series.oscillators;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${DateFormat('yyyy.MM.dd').format(date)} 시작 주',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: '봉 상세 닫기',
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            Text(
                              candle.isClosed
                                  ? '마감된 주봉'
                                  : '진행 중 · 가격과 지표가 바뀔 수 있습니다.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: trendMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final item in <(String, double?)>[
                              ('시가', candle.open),
                              ('고가', candle.high),
                              ('저가', candle.low),
                              (candle.isClosed ? '종가' : '현재가', candle.close),
                              ('거래량 (BTC)', candle.volume),
                              ('RSI (14)', osc.rsi[index]),
                              ('MACD', osc.macd[index]),
                              ('Signal', osc.signal[index]),
                              ('Histogram', osc.histogram[index]),
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.$1,
                                        style: const TextStyle(
                                          color: trendMuted,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      value(item.$2),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(),
                            Text(
                              '주봉 시작: 월요일 00:00 UTC · 한국 시간 09:00\n마지막 수신: ${DateFormat('MM/dd HH:mm:ss').format(data.snapshot.receivedAt.toLocal())} (기기 시간)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: trendMuted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  void _settings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => AnimatedBuilder(
            animation: controller,
            builder:
                (context, _) => SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '차트 설정',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: '설정 닫기',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          for (final line in TrendLine.values)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                line.formula,
                                style: TextStyle(color: line.color),
                              ),
                              subtitle:
                                  line == TrendLine.baseline
                                      ? const Text('항상 표시')
                                      : null,
                              value: controller.visibleLines.contains(line),
                              onChanged:
                                  line == TrendLine.baseline
                                      ? null
                                      : (v) => controller.toggleLine(line, v!),
                            ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text('RSI'),
                            value: controller.showRsi,
                            onChanged: controller.setRsi,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text('MACD'),
                            value: controller.showMacd,
                            onChanged: controller.setMacd,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text('로그 가격축'),
                            value: controller.logarithmic,
                            onChanged: controller.setLogarithmic,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onRefresh();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('데이터 다시 연결'),
                          ),
                          const Divider(),
                          const Text(
                            '자석을 켜면 터치 위치에서 18px 이내의 시가·고가·저가·종가 중 가장 가까운 점에 맞춥니다. 멀리 누르거나 자석을 끄면 그 위치의 자유 가격을 표시합니다. 자석 전환 시 선택을 해제하며, 다음 터치부터 적용됩니다. 길게 누른 채 움직이면 교차선을 이동할 수 있습니다. 자유 가격은 실제 체결 가격이 아닐 수 있습니다.\n\n가격 차트 내부를 더블 클릭하거나 두 번 탭하면 RSI·MACD를 잠시 숨기고 가격 차트를 최대화합니다. 다시 두 번 탭하거나 상단 지표 다시 표시 버튼을 누르면 복원됩니다. 날짜·가격축 두 번 탭은 기존 초기화 동작을 유지합니다.\n\n마우스 휠을 위로 굴리면 오른쪽 기준으로 확대하고, 아래로 굴리면 왼쪽의 과거 봉이 더 보입니다. 핀치로도 기간을 확대·축소하며, 좌우 드래그로 이동합니다. 가격 차트 안에서 한 손가락을 상하좌우로 드래그하면 차트가 이동합니다. 대각선으로도 이동할 수 있습니다. 상하 이동을 하면 수동 가격축으로 전환됩니다. RSI·MACD의 세로축은 자동으로 유지합니다. 페이지 스크롤은 차트 바깥에서 시작하세요. 아래 날짜 눈금을 왼쪽으로 당기면 확대하고 오른쪽으로 당기면 축소합니다. 날짜 눈금 두 번 탭은 최근 60주로 돌아옵니다. 오른쪽 가격 눈금을 위아래로 드래그하면 가격축 배율이 바뀝니다. 가격 눈금 두 번 탭 또는 상단 자동 맞춤 버튼으로 자동 가격축에 복귀합니다. 탭하거나 길게 눌러 같은 주의 값을 확인하세요.\n\n'
                            '주봉은 월요일 00:00 UTC에 시작합니다. 한국 시간으로는 월요일 오전 9시입니다. 날짜 눈금은 이 주의 시작 날짜이며, 수신 시각은 기기 시간으로 표시합니다.\n\n'
                            'RSI는 14주 변화량, MACD는 12·26주 EMA와 9주 Signal입니다. 현재 주의 캔들·기준선·보조지표는 마감 전까지 바뀝니다. 점수는 현재 수신 가격과 같은 주봉 스냅샷으로 판단하며, 과거 봉 선택으로 바뀌지 않습니다.\n\n'
                            '조회된 최대 1,000개 주봉 안에서 조작합니다. 수신이 지연되면 차트는 유지하고 추세·종합 점수 산출은 보류합니다.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: trendMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }
}

// 외부 아이콘 패키지 없이 그리는 U자 자석 아이콘.
class _MagnetIconPainter extends CustomPainter {
  final Color color;
  const _MagnetIconPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(4, 3)
          ..lineTo(4, 11)
          ..cubicTo(4, 19, 16, 19, 16, 11)
          ..lineTo(16, 3);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawLine(
      const Offset(2, 7),
      const Offset(6, 7),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      const Offset(14, 7),
      const Offset(18, 7),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MagnetIconPainter oldDelegate) =>
      color != oldDelegate.color;
}
