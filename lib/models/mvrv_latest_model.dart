import 'package:btc_horizon/models/mvrv_history_model.dart';

/// 최신 확정 MVRV 값과 해당 자료의 기준·수집·확인 정보를 담습니다.
class MvrvLatestModel {
  /// 최신 확정 기록: 기준일, BTC 가격, MVRV Z Score.
  final MvrvHistoryPointModel latestConfirmed;

  /// 원본 응답의 기준일.
  /// 기존 일별 모델과 동일하게 UTC 자정으로 표현합니다.
  final DateTime asOfDate;

  /// 원본에서 제공한 확정 자료의 마지막 기준일.
  final DateTime completeThrough;

  /// 서버가 수집 결과를 Firestore에 저장한 시각.
  final DateTime collectedAt;

  /// 앱이 서버 문서를 성공적으로 읽고 검증한 시각.
  /// Firestore에 저장하지 않고 앱에서 생성합니다.
  final DateTime checkedAt;

  /// 저장된 데이터 묶음의 버전 식별자.
  final String revision;

  /// 데이터 출처.
  final String source;

  const MvrvLatestModel({
    required this.latestConfirmed,
    required this.asOfDate,
    required this.completeThrough,
    required this.collectedAt,
    required this.checkedAt,
    required this.revision,
    required this.source,
  });
}
