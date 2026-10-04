import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IndicatorTable extends StatelessWidget {
  final List<IndicatorSummaryModel> indicators;

  static final DateFormat _dataDateFormat = DateFormat('yyyy.MM.dd');

  const IndicatorTable({super.key, required this.indicators});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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

          for (final indicator in indicators) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(indicator.label, maxLines: 2, overflow: TextOverflow.ellipsis),

                      // 데이터 기준일이 있는 지표에만 표시합니다.
                      if (indicator.dataDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '기준 ${_dataDateFormat.format(indicator.dataDate!)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                        ),
                      ],
                    ],
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
                    indicator.score == null ? '-' : '${indicator.score!.toStringAsFixed(0)}/100',
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
    );
  }
}
