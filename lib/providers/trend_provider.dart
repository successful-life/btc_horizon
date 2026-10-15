import 'package:btc_horizon/data/cycle_indicator_config.dart';
import 'package:btc_horizon/enums/cycle_indicator_type.dart';
import 'package:btc_horizon/models/cycle_indicator_model.dart';
import 'package:btc_horizon/models/indicator_summary_model.dart';
import 'package:btc_horizon/models/trend_detail_model.dart';
import 'package:btc_horizon/providers/trend_market_data_provider.dart';
import 'package:btc_horizon/utils/trend_calculator.dart';
import 'package:btc_horizon/utils/trend_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 현재 주봉의 마지막 가격과 같은 스냅샷의 기준선을 사용합니다.
/// 과거 봉 선택이나 확대 조작으로 홈·종합 점수가 바뀌지 않습니다.
final trendProvider = Provider<AsyncValue<TrendDetailModel>>((ref) {
  return ref.watch(trendMarketProvider).whenData((market) {
    final candle = market.series.candles.last;
    final lines = market.lines;
    final all = [
      lines.trendBaseline,
      lines.upperTrendThreshold,
      lines.lowerTrendThreshold,
      lines.bottomRangeBoundary,
    ];
    if (all.any((line) => line.isEmpty)) {
      throw StateError('추세 판단에는 진행 중인 봉을 포함하여 최소 280개 주봉이 필요합니다.');
    }
    final values = all.map((line) => line.last.value).toList();
    final status = calculateTrendStatus(
      currentBtcPrice: candle.close,
      trendBaseline: values[0],
      upperTrendThreshold: values[1],
      lowerTrendThreshold: values[2],
      bottomRangeBoundary: values[3],
    );
    final names = ['장기 추세 기준선', '중·단기 추세선', '하락 심화 참고선', '장기 저점 참고선'];
    final live = market.snapshot.isLive;
    final indicators = [
      for (var i = 0; i < values.length; i++)
        IndicatorSummaryModel(
          label: names[i],
          value:
              '${calculateDifferencePercent(currentPrice: candle.close, movingAverage: values[i]).toStringAsFixed(2)}%',
          status: live
              ? getPriceRelationStatus(
                  calculateDifferencePercent(currentPrice: candle.close, movingAverage: values[i]),
                )
              : '수신 지연',
          dataDate: market.snapshot.receivedAt,
        ),
    ];
    return TrendDetailModel(
      summary: CycleIndicatorModel(
        type: CycleIndicatorType.trend,
        title: '추세',
        score: live ? status.score : null,
        weight: kTrendWeight,
        indicators: indicators,
      ),
      chartData: lines,
      reference: TrendReference(
        status: status,
        price: candle.close,
        receivedAt: market.snapshot.receivedAt,
        weekStart: candle.openTime,
        baselineValue: values[0],
        isLive: live,
        isProvisional: !candle.isClosed,
      ),
    );
  });
});
