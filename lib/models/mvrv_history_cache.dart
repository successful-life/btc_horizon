import 'package:btc_horizon/models/mvrv_history_model.dart';

/// 서버에서 검증한 차트 전체 기록을 기기에 보관하는 단위입니다.
class MvrvHistoryCache {
  static const formatVersion = 1;

  final String revision;
  final DateTime lastVerifiedAt;
  final MvrvHistoryModel history;

  const MvrvHistoryCache._({
    required this.revision,
    required this.lastVerifiedAt,
    required this.history,
  });

  /// 서버 조회·검증을 마친 전체 기록으로 저장본을 만듭니다.
  factory MvrvHistoryCache.fromHistory({
    required String revision,
    required DateTime lastVerifiedAt,
    required MvrvHistoryModel history,
  }) {
    return MvrvHistoryCache.fromJson({
      'cacheVersion': formatVersion,
      'revision': revision,
      'lastVerifiedAt': lastVerifiedAt.toUtc().toIso8601String(),
      'pointCount': history.points.length,
      'history': history.toJson(),
    });
  }

  Map<String, dynamic> toJson() => {
    'cacheVersion': formatVersion,
    'revision': revision,
    'lastVerifiedAt': lastVerifiedAt.toUtc().toIso8601String(),
    'pointCount': history.points.length,
    'history': history.toJson(),
  };

  factory MvrvHistoryCache.fromJson(Map<String, dynamic> json) {
    if (json['cacheVersion'] is! int || json['cacheVersion'] != formatVersion) {
      throw const FormatException('지원하지 않는 MVRV 캐시 형식입니다.');
    }

    final revision = json['revision'];
    final verifiedText = json['lastVerifiedAt'];
    final pointCount = json['pointCount'];
    final rawHistory = json['history'];

    if (revision is! String || revision.trim().isEmpty) {
      throw const FormatException('MVRV 캐시의 서버 버전이 없습니다.');
    }

    if (verifiedText is! String) {
      throw const FormatException('MVRV 캐시의 확인 시각이 없습니다.');
    }

    final verifiedAt = DateTime.tryParse(verifiedText);

    // 이 앱이 저장하는 UTC ISO 형식만 허용합니다.
    // 잘못된 날짜가 다음 달로 자동 보정되는 경우도 거릅니다.
    if (verifiedAt == null || !verifiedAt.isUtc || verifiedAt.toIso8601String() != verifiedText) {
      throw const FormatException('MVRV 캐시의 확인 시각이 올바르지 않습니다.');
    }

    // 현재 서버가 허용하는 최대 100개 연도에 맞춘 상한입니다.
    if (pointCount is! int || pointCount <= 0 || pointCount > 36600) {
      throw const FormatException('MVRV 캐시의 기록 수가 올바르지 않습니다.');
    }

    if (rawHistory is! Map) {
      throw const FormatException('MVRV 캐시의 차트 기록이 없습니다.');
    }

    final rawSeries = rawHistory['series'];

    if (rawSeries is! List || rawSeries.length != pointCount) {
      throw const FormatException('MVRV 캐시의 기록 수가 일치하지 않습니다.');
    }

    final MvrvHistoryModel history;

    try {
      history = MvrvHistoryModel.fromJson(Map<String, dynamic>.from(rawHistory));
    } on TypeError {
      throw const FormatException('MVRV 캐시의 기록 형식이 올바르지 않습니다.');
    }

    if (history.source.trim().isEmpty) {
      throw const FormatException('MVRV 캐시의 출처가 없습니다.');
    }

    if (history.completeThrough.isAfter(history.asOfDate) ||
        history.points.last.date.isAfter(history.asOfDate) ||
        !history.points.any((point) => !point.date.isAfter(history.completeThrough))) {
      throw const FormatException('MVRV 캐시의 기준일과 기록 범위가 맞지 않습니다.');
    }

    return MvrvHistoryCache._(revision: revision, lastVerifiedAt: verifiedAt, history: history);
  }
}
