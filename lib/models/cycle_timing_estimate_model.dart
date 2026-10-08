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

  DateTime startDateFor({required bool sameType}) => sameType ? sameTypeAnchorDate : anchorDate;

  int durationDaysFor({required bool sameType}) {
    final start = startDateFor(sameType: sameType);
    return DateTime.utc(
      centerDate.year,
      centerDate.month,
      centerDate.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  }
}
