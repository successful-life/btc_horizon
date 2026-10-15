import 'package:flutter/material.dart';
import 'package:btc_horizon/models/trend_chart_data_model.dart';

const trendInk = Color(0xFF172033);
const trendMuted = Color(0xFF667085);
const trendGrid = Color(0xFFEAECF0);
const trendUp = Color(0xFF16866B);
const trendDown = Color(0xFFD94B60);

enum TrendLine {
  baseline('장기 추세', '장기 추세 기준선', Color(0xFF334155)),
  upper('중·단기', '중·단기 추세선', Color(0xFFEC4899)),
  lower('하락 심화', '하락 심화 참고선', Color(0xFFB45309)),
  bottom('장기 저점', '장기 저점 참고선', Color(0xFF7C3AED));

  const TrendLine(this.label, this.formula, this.color);
  final String label, formula;
  final Color color;
  double get strokeWidth => switch (this) {
    baseline => 2.4,
    upper => 2.2,
    lower || bottom => 1.5,
  };
  List<TrendChartPoint> points(TrendChartDataModel data) => switch (this) {
    baseline => data.trendBaseline,
    upper => data.upperTrendThreshold,
    lower => data.lowerTrendThreshold,
    bottom => data.bottomRangeBoundary,
  };
}

BoxDecoration trendCardDecoration() =>
    BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18));
