import 'package:btc_horizon/models/cycle_timing_analysis_chart_model.dart';
import 'package:btc_horizon/widgets/cycle_timing_analysis_chart.dart';
import 'package:flutter/material.dart';

class CycleTimingFullscreenScreen extends StatefulWidget {
  final CycleTimingAnalysisChartModel data;
  final CycleTimingChartView? initialView;
  final ValueChanged<CycleTimingChartView>? onViewChanged;

  const CycleTimingFullscreenScreen({
    super.key,
    required this.data,
    this.initialView,
    this.onViewChanged,
  });

  @override
  State<CycleTimingFullscreenScreen> createState() => _CycleTimingFullscreenScreenState();
}

class _CycleTimingFullscreenScreenState extends State<CycleTimingFullscreenScreen> {
  // 드롭다운의 PopupRoute도 회전 영역 안에서 열리도록 합니다.
  final _popupNavigatorKey = GlobalKey<NavigatorState>();
  CycleTimingChartView? _view;

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
  }

  void _saveView(CycleTimingChartView view) {
    _view = view;
    widget.onViewChanged?.call(view);
  }

  void _closeFullscreen() {
    // 이 State의 context는 내부 Navigator 바깥이므로 확대 화면을 닫습니다.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final rotate = constraints.maxHeight > constraints.maxWidth;
            final size = rotate
                ? Size(constraints.maxHeight, constraints.maxWidth)
                : Size(constraints.maxWidth, constraints.maxHeight);
            return RotatedBox(
              quarterTurns: rotate ? 1 : 0,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: size),
                child: NavigatorPopHandler<Object?>(
                  // 메뉴가 열려 있으면 시스템 뒤로가기는 메뉴부터 닫습니다.
                  onPopWithResult: (_) => _popupNavigatorKey.currentState?.pop(),
                  child: Navigator(
                    key: _popupNavigatorKey,
                    onGenerateRoute: (settings) =>
                        MaterialPageRoute<void>(settings: settings, builder: _buildContent),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '고·저점 주기 분석',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF172033),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '확대 화면 닫기',
                  onPressed: _closeFullscreen,
                  icon: const Icon(Icons.fullscreen_exit_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAECF0)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: LayoutBuilder(
                builder: (context, chartConstraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
                  if (chartConstraints.maxHeight < 290 ||
                      chartConstraints.maxWidth < 720 ||
                      textScale > 1.4) {
                    return SingleChildScrollView(
                      child: CycleTimingAnalysisChart(
                        data: widget.data,
                        initialView: _view,
                        onViewChanged: _saveView,
                      ),
                    );
                  }
                  return CycleTimingAnalysisChart(
                    data: widget.data,
                    fillAvailableSpace: true,
                    initialView: _view,
                    onViewChanged: _saveView,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
