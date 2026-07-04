import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:flutter/material.dart';

class CycleIndicatorDetailScreen extends StatelessWidget {
  final CycleIndicatorModel cycleIndicatorModel;

  const CycleIndicatorDetailScreen({super.key, required this.cycleIndicatorModel});

  @override
  Widget build(BuildContext context) {
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
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cycleIndicatorModel.title,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Column(
                        children: [
                          Text('${cycleIndicatorModel.score ?? '-'} / 100'),
                          const SizedBox(height: 10),
                          const Text('저평가 (하드코딩 임시값)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Indicator
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('지표'), Text('현재 값'), Text('점수')],
                    ),
                    const SizedBox(height: 10),
                    for (final indicator in cycleIndicatorModel.indicators)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(flex: 2, child: Text(indicator.label)),
                          Expanded(flex: 2, child: Text(indicator.value)),
                          Expanded(flex: 1, child: Text(indicator.score?.toString() ?? '-')),
                        ],
                      ),
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
