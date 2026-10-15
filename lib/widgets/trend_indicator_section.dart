import 'package:btc_horizon/models/trend_detail_model.dart';
import 'package:btc_horizon/widgets/trend_chart_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrendIndicatorSection extends StatelessWidget {
  final TrendDetailModel detail;
  const TrendIndicatorSection({super.key, required this.detail});
  @override
  Widget build(BuildContext context) {
    final reference = detail.reference;
    if (reference == null || detail.summary.indicators.length < 4) return const SizedBox.shrink();
    final above = reference.price >= reference.baselineValue;
    final indices = above ? [0, 1] : [0, 2, 3];
    const descriptions = [
      '상승·하락 추세를 구분하는 중심 기준과의 차이입니다.',
      '중·단기 추세의 유지 여부를 살펴보는 기준과의 차이입니다.',
      '장기 추세선 아래에서 하락 상태를 구분하는 기준과의 차이입니다.',
      '장기 저점 가격대를 살펴보는 참고선과의 차이입니다. 저점이나 반등을 확정하는 선은 아닙니다.',
    ];
    return Container(
      decoration: trendCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        key: const PageStorageKey('trend-judgment-details'),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          '추세 판단 근거',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: trendInk),
        ),
        subtitle: const Text('현재가와 기준선의 차이', style: TextStyle(fontSize: 11, color: trendMuted)),
        children: [
          for (final index in indices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        TrendLine.values[index].formula,
                        style: const TextStyle(fontSize: 13, color: trendInk),
                      ),
                      Text(
                        detail.summary.indicators[index].value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: TrendLine.values[index].color,
                        ),
                      ),
                      Text(
                        detail.summary.indicators[index].status ?? '—',
                        style: const TextStyle(fontSize: 12, color: trendMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descriptions[index],
                    style: const TextStyle(fontSize: 12, height: 1.4, color: trendMuted),
                  ),
                ],
              ),
            ),
          const Divider(color: trendGrid),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '수신 ${DateFormat('MM/dd HH:mm:ss').format(reference.receivedAt.toLocal())} · 기기 시간\n'
              '${DateFormat('yyyy/MM/dd').format(reference.weekStart)} 시작 주 · ${reference.isProvisional ? '미확정' : '마감'}',
              style: const TextStyle(fontSize: 11, height: 1.5, color: trendMuted),
            ),
          ),
        ],
      ),
    );
  }
}
