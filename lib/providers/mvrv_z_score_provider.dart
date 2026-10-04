import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/providers/mvrv_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mvrvZScoreProvider = Provider<AsyncValue<MvrvHistoryPointModel>>((ref) {
  final historyAsync = ref.watch(mvrvHistoryProvider);

  return historyAsync.whenData((history) {
    return history.points.lastWhere(
      (point) => !point.date.isAfter(history.completeThrough),
      orElse: () {
        throw const FormatException('점수 계산에 사용할 완료된 MVRV 데이터가 없습니다.');
      },
    );
  });
});
