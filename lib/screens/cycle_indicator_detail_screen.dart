import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:btc_horizon/screens/trend_detail_screen.dart';
import 'package:btc_horizon/widgets/indicator_table.dart';
import 'package:btc_horizon/widgets/trend_chart.dart';
import 'package:btc_horizon/widgets/trend_indicator_section.dart';
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
              if (cycleIndicatorModel.type == CycleIndicatorType.trend)
                TrendIndicatorSection(indicators: cycleIndicatorModel.indicators)
              else
                IndicatorTable(indicators: cycleIndicatorModel.indicators),

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
