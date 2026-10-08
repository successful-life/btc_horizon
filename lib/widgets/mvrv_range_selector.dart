import 'chart_range_selector.dart';

// 기존 MVRV 호출부를 유지하면서 공용 기간 선택기를 재사용합니다.
class MvrvRangeSelector extends ChartRangeSelector {
  MvrvRangeSelector({
    super.key,
    required super.overviewPoints,
    required super.values,
    required super.minimumSpan,
    required super.firstDate,
    required super.lastDate,
    required super.onChanged,
    super.height,
  });
}
