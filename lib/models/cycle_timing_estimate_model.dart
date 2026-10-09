import 'package:btc_horizon/enums/cycle_timing_estimate_type.dart';

class CycleTimingEstimateModel {
  final CycleTimingEstimateType type;
  // 예측의 출발점인 마지막 등록 고점 또는 저점입니다.
  final DateTime anchorDate;
  // 예상 대상과 같은 종류의 마지막 등록 날짜입니다.
  // 예상 저점이면 마지막 저점, 예상 고점이면 마지막 고점입니다.
  final DateTime sameTypeAnchorDate;
  final DateTime centerDate;
  final DateTime rangeStartDate;
  final DateTime rangeEndDate;

  const CycleTimingEstimateModel({
    required this.type,
    required this.anchorDate,
    required this.sameTypeAnchorDate,
    required this.centerDate,
    required this.rangeStartDate,
    required this.rangeEndDate,
  });

  // 표시 기간을 잘라도 전체 예상 일수는 유지합니다.
  int get estimatedDurationDays => durationDaysFor(sameType: false);

  DateTime startDateFor({required bool sameType}) =>
      sameType ? sameTypeAnchorDate : anchorDate;

  // 범위 계산은 [시작일, 종료일)이므로 표시용 마지막 날짜를 한곳에서 정합니다.
  DateTime get rangeLastIncludedDate =>
      DateTime.utc(rangeEndDate.year, rangeEndDate.month, rangeEndDate.day - 1);

  ({int startDays, int endDays}) durationRangeDaysFor({
    required bool sameType,
  }) {
    final start = startDateFor(sameType: sameType);
    return (
      startDays: _dayDifference(rangeStartDate, start),
      endDays: _dayDifference(rangeLastIncludedDate, start),
    );
  }

  int durationDaysFor({required bool sameType}) {
    return _dayDifference(centerDate, startDateFor(sameType: sameType));
  }

  int _dayDifference(DateTime end, DateTime start) {
    return DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  }
}
