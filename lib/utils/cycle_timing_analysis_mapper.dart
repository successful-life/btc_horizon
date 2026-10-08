import 'package:btc_horizon/models/bitstamp_ohlc_model.dart';
import 'package:btc_horizon/models/cycle_timing_analysis_chart_model.dart';
import 'package:btc_horizon/models/cycle_timing_analysis_model.dart';
import 'package:btc_horizon/models/cycle_timing_chart_point_model.dart';
import 'package:btc_horizon/models/cycle_timing_interval_model.dart';

// 날짜의 시·분·초 대신 현재 앱에서 사용하는 연·월·일로 정렬한다.
// UTC로 시점을 변환하는 함수가 아니라, 달력 날짜의 비교 키다.
int _dayKey(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

CycleTimingAnalysisChartModel buildCycleTimingAnalysisChartData({
  required CycleTimingAnalysisModel analysis,
  required List<BitstampOhlcModel> ohlcList,
}) {
  final asOfDay = _dayKey(analysis.asOfDate);
  final topDates = <int, DateTime>{};
  final bottomDates = <int, DateTime>{};

  void addDate(Map<int, DateTime> dates, DateTime date) {
    final day = _dayKey(date);
    if (day <= asOfDay) dates[day] = DateTime(date.year, date.month, date.day);
  }

  for (final interval in analysis.bottomToTopIntervals) {
    addDate(bottomDates, interval.startDate);
    addDate(topDates, interval.endDate);
  }
  for (final interval in analysis.topToBottomIntervals) {
    addDate(topDates, interval.startDate);
    addDate(bottomDates, interval.endDate);
  }

  final eventDays = {...topDates.keys, ...bottomDates.keys}.toList()..sort();
  if (eventDays.isEmpty) {
    throw StateError('표시할 고·저점 기준 날짜가 없습니다.');
  }

  // 첫 분석 지점 앞에 90일의 가격 흐름을 보여준다.
  final firstVisibleDay = eventDays.first - 90;
  final dailyPrices = <int, CycleTimingChartPointModel>{};

  for (final candle in ohlcList) {
    final day = _dayKey(candle.openTime);
    if (day < firstVisibleDay || day > asOfDay) continue;

    if (!candle.close.isFinite || candle.close <= 0) {
      throw StateError('로그 차트에 사용할 종가는 양수여야 합니다.');
    }

    dailyPrices[day] = CycleTimingChartPointModel(
      date: DateTime(candle.openTime.year, candle.openTime.month, candle.openTime.day),
      closePrice: candle.close,
    );
  }

  final sortedDays = dailyPrices.keys.toList()..sort();
  if (sortedDays.length < 2) {
    throw StateError('차트를 그릴 가격 데이터가 부족합니다.');
  }

  // 일부 히스토리만 받은 상태를 완성된 장기 차트처럼 보여주지 않는다.
  if (sortedDays.first > eventDays.first || sortedDays.last < eventDays.last) {
    throw StateError('고·저점 분석 기간 전체를 포함하는 가격 데이터가 필요합니다.');
  }

  // 실제로 수신한 일별 종가를 모두 보존합니다.
  // 날짜 축의 눈금 간격과 가격 데이터의 간격은 별도로 관리합니다.
  final pricePoints = [for (final day in sortedDays) dailyPrices[day]!];

  List<CycleTimingIntervalModel> connectDates(Map<int, DateTime> dates) {
    final sorted = dates.values.toList()..sort();
    return [
      for (int i = 0; i + 1 < sorted.length; i++)
        CycleTimingIntervalModel(startDate: sorted[i], endDate: sorted[i + 1]),
    ];
  }

  return CycleTimingAnalysisChartModel(
    analysis: analysis,
    pricePoints: pricePoints,
    topToTopIntervals: connectDates(topDates),
    bottomToBottomIntervals: connectDates(bottomDates),
  );
}
