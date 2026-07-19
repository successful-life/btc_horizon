import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:flutter/material.dart';

class CycleIndicatorDetailScreen extends StatelessWidget {
  final CycleIndicatorModel cycleIndicatorModel;

  const CycleIndicatorDetailScreen({super.key, required this.cycleIndicatorModel});

  @override
  Widget build(BuildContext context) {
    final categoryScoreText = cycleIndicatorModel.score == null
        ? '-'
        : cycleIndicatorModel.score!.toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(title: Text('${cycleIndicatorModel.title} 상세')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1. Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.lightGreenAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.insert_chart_outlined_sharp),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cycleIndicatorModel.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$categoryScoreText / 100'),
                          const SizedBox(height: 10),
                          const Text('저평가 (임시)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('지표', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '현재 값',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '환산 점수',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '상태',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    for (final indicator in cycleIndicatorModel.indicators) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              indicator.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              indicator.value,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              indicator.score == null
                                  ? '-'
                                  : '${indicator.score!.toStringAsFixed(0)}/100',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              indicator.status ?? '-',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Analysis
              const Text('해석 영역(임시)'),
              const SizedBox(height: 20),

              // 4. Update Date
              const Text('업데이트 날짜 영역(임시)'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
