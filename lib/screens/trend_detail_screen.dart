import 'package:btc_horizon/models/trend_chart_data_model.dart';
import 'package:btc_horizon/models/trend_detail_model.dart';
import 'package:btc_horizon/widgets/trend_chart.dart';
import 'package:btc_horizon/widgets/trend_indicator_section.dart';
import 'package:btc_horizon/widgets/trend_legend.dart';
import 'package:flutter/material.dart';

class TrendDetailScreen extends StatelessWidget {
  final TrendDetailModel trendDetailModel;

  const TrendDetailScreen({super.key, required this.trendDetailModel});

  @override
  Widget build(BuildContext context) {
    final summary = trendDetailModel.summary;

    return Scaffold(
      appBar: AppBar(title: const Text('추세 상세')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TrendChart(data: trendDetailModel.chartData),

            const SizedBox(height: 12),

            TrendLegend(),

            const SizedBox(height: 20),

            TrendIndicatorSection(indicators: summary.indicators),

            const SizedBox(height: 20),

            // Analysis
          ],
        ),
      ),
    );
  }
}
