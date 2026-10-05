import 'package:flutter/material.dart';

import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/widgets/mvrv_history_chart.dart';

class MvrvFullscreenScreen extends StatelessWidget {
  final MvrvHistoryModel history;

  const MvrvFullscreenScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shouldRotate = constraints.maxHeight > constraints.maxWidth;
            final contentSize = shouldRotate
                ? Size(constraints.maxHeight, constraints.maxWidth)
                : Size(constraints.maxWidth, constraints.maxHeight);

            return RotatedBox(
              quarterTurns: shouldRotate ? 1 : 0,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: contentSize),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'MVRV Z-Score',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF172033),
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: '확대 화면 닫기',
                            icon: const Icon(Icons.fullscreen_exit_rounded),
                            onPressed: () => Navigator.of(context).pop(),
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
                            // 기간 선택기가 추가된 만큼 최소 높이도 확보합니다.
                            // 작은 창이나 큰 글꼴에서는 차트를 잘라내지 않고 스크롤합니다.
                            if (chartConstraints.maxHeight < 260 || textScale > 1.5) {
                              return SingleChildScrollView(
                                child: MvrvHistoryChart(history: history),
                              );
                            }
                            return MvrvHistoryChart(history: history, fillAvailableSpace: true);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
