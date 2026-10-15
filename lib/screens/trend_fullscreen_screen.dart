import 'package:btc_horizon/widgets/trend_chart.dart';
import 'package:btc_horizon/widgets/trend_chart_controller.dart';
import 'package:flutter/material.dart';

class TrendFullscreenScreen extends StatefulWidget {
  final TrendChartController controller;
  const TrendFullscreenScreen({super.key, required this.controller});
  @override
  State<TrendFullscreenScreen> createState() => _TrendFullscreenScreenState();
}

class _TrendFullscreenScreenState extends State<TrendFullscreenScreen> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final rotate = box.maxHeight > box.maxWidth;
          final size =
              rotate
                  ? Size(box.maxHeight, box.maxWidth)
                  : Size(box.maxWidth, box.maxHeight);
          return RotatedBox(
            quarterTurns: rotate ? 1 : 0,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: size),
              child: NavigatorPopHandler<Object?>(
                onPopWithResult: (_) => _navigator.currentState?.pop(),
                child: Navigator(
                  key: _navigator,
                  onGenerateRoute:
                      (settings) => MaterialPageRoute<void>(
                        settings: settings,
                        builder:
                            (_) => Material(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  2,
                                  12,
                                  4,
                                ),
                                child: TrendChartPanel(
                                  controller: widget.controller,
                                  fullscreen: true,
                                  onClose: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ),
                      ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
