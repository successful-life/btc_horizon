import 'package:btc_horizon/models/mvrv_latest_model.dart';

/// 앱의 초기 안내 기준입니다.
/// 데이터 제공업체의 갱신 보장이나 점수 유효기간을 뜻하지 않습니다.
const kMvrvMaxSourceLagDays = 3;
const kMvrvMaxCollectionAge = Duration(hours: 36);

/// 기기 시각과 서버 시각 사이의 작은 오차를 허용합니다.
const kMvrvClockTolerance = Duration(minutes: 5);

/// 마지막 앱 확인 시점을 기준으로 판단한 결과입니다.
class MvrvFreshness {
  /// 앱 확인 날짜와 값 기준일 사이의 UTC 달력 날짜 차이.
  final int sourceLagDays;

  /// 서버 저장부터 앱 확인까지의 경과 시간.
  final Duration collectionAge;

  /// 미래 날짜 또는 허용 범위를 넘는 시각 불일치 여부.
  final bool needsClockCheck;

  const MvrvFreshness({
    required this.sourceLagDays,
    required this.collectionAge,
    required this.needsClockCheck,
  });

  /// 시각에 문제가 있으면 오래됐는지 판정하지 않습니다.
  bool get isSourceDateOld => !needsClockCheck && sourceLagDays > kMvrvMaxSourceLagDays;

  bool get isCollectionOld => !needsClockCheck && collectionAge > kMvrvMaxCollectionAge;
}

/// 실시간 현재 시각이 아니라 data.checkedAt 시점의 상태를 계산합니다.
MvrvFreshness evaluateMvrvFreshness(MvrvLatestModel data) {
  final checkedAt = data.checkedAt.toUtc();
  final collectedAt = data.collectedAt.toUtc();
  final referenceDate = data.latestConfirmed.date.toUtc();

  final checkedDay = DateTime.utc(checkedAt.year, checkedAt.month, checkedAt.day);

  final referenceDay = DateTime.utc(referenceDate.year, referenceDate.month, referenceDate.day);

  final sourceLagDays = checkedDay.difference(referenceDay).inDays;

  final collectionAge = checkedAt.difference(collectedAt);

  final sourceDateIsInFuture = sourceLagDays < 0;

  final collectionTimeIsInFuture = collectedAt.isAfter(checkedAt.add(kMvrvClockTolerance));

  return MvrvFreshness(
    sourceLagDays: sourceLagDays,
    collectionAge: collectionAge,
    needsClockCheck: sourceDateIsInFuture || collectionTimeIsInFuture,
  );
}
