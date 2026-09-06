import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:flutter/material.dart';

class CycleIndicatorDetailHeader extends StatelessWidget {
  final CycleIndicatorModel cycleIndicatorModel;

  const CycleIndicatorDetailHeader({super.key, required this.cycleIndicatorModel});

  @override
  Widget build(BuildContext context) {
    final categoryScoreText = cycleIndicatorModel.score == null
        ? '-'
        : cycleIndicatorModel.score!.toStringAsFixed(1);

    return Container(
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
              children: [Text('$categoryScoreText / 100'), const SizedBox(height: 10)],
            ),
          ],
        ),
      ),
    );
  }
}
