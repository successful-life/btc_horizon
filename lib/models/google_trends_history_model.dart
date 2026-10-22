import 'package:cloud_firestore/cloud_firestore.dart';

enum GoogleTrendsRegion {
  korea('KR', '한국', '비트코인', 'kr_bitcoin_monthly'),
  worldwide('GLOBAL', '전 세계', 'bitcoin', 'global_bitcoin_monthly');

  const GoogleTrendsRegion(this.country, this.label, this.query, this.documentId);
  final String country;
  final String label;
  final String query;
  final String documentId;

  String get documentPath => 'search_interest_latest/$documentId';
}

class GoogleTrendsPoint {
  const GoogleTrendsPoint({required this.month, required this.value, required this.isPartial});
  final DateTime month;
  final int value;
  final bool? isPartial;
}

class GoogleTrendsHistoryModel {
  const GoogleTrendsHistoryModel({
    this.region = GoogleTrendsRegion.korea,
    required this.points,
    required this.collectedAt,
    required this.requestedEnd,
    required this.fromCache,
  });

  final GoogleTrendsRegion region;
  final List<GoogleTrendsPoint> points;
  final DateTime collectedAt;
  final DateTime requestedEnd;
  final bool fromCache;

  bool isProvisional(GoogleTrendsPoint point) {
    final nextMonth = DateTime.utc(point.month.year, point.month.month + 1);
    return point.isPartial == true ||
        nextMonth.isAfter(requestedEnd.add(const Duration(days: 1))) ||
        nextMonth.isAfter(collectedAt.toUtc());
  }

  factory GoogleTrendsHistoryModel.fromMap(
    Map<String, dynamic> data, {
    bool fromCache = false,
    GoogleTrendsRegion? expectedRegion,
  }) {
    final matches = GoogleTrendsRegion.values.where(
      (region) => data['country'] == region.country && data['query'] == region.query,
    );
    if (matches.length != 1 || (expectedRegion != null && matches.single != expectedRegion)) {
      throw const FormatException('검색 관심도의 지역과 검색어가 일치하지 않습니다.');
    }
    final region = matches.single;
    if (data['schemaVersion'] != 1 ||
        data['kind'] != 'term' ||
        data['granularity'] != 'monthly' ||
        data['searchType'] != 'web' ||
        data['category'] != 0 ||
        data['source'] != 'Google Trends' ||
        data['normalization'] != 'single_term_request_0_100' ||
        data['requestedStartDate'] != '2009-01-03') {
      throw const FormatException('검색 관심도 조회 조건이 일치하지 않습니다.');
    }
    final collected = data['collectedAt'];
    final rawEnd = data['requestedEndDate'];
    final rawPoints = data['points'];
    if (collected is! Timestamp ||
        rawEnd is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawEnd) ||
        rawPoints is! List ||
        rawPoints.length < 2 ||
        rawPoints.length > 600 ||
        data['pointCount'] != rawPoints.length) {
      throw const FormatException('검색 관심도 자료 형식이 올바르지 않습니다.');
    }
    final end = DateTime.tryParse('${rawEnd}T00:00:00Z');
    if (end == null || end.toIso8601String().substring(0, 10) != rawEnd) {
      throw const FormatException('조회 종료일 오류');
    }
    final points = <GoogleTrendsPoint>[];
    int? previous;
    for (final raw in rawPoints) {
      if (raw is! Map || raw['month'] is! String) {
        throw const FormatException('월별 기록 오류');
      }
      final text = raw['month'] as String;
      if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(text)) {
        throw const FormatException('월 형식 오류');
      }
      final month = DateTime.utc(int.parse(text.substring(0, 4)), int.parse(text.substring(5)));
      final key = month.year * 12 + month.month;
      final value = raw['value'];
      final partial = raw['isPartial'];
      if ((previous != null && key != previous + 1) ||
          month.isAfter(end) ||
          value is! num ||
          !value.isFinite ||
          value % 1 != 0 ||
          value < 0 ||
          value > 100 ||
          (partial != null && partial is! bool)) {
        throw const FormatException('누락·중복된 월 또는 잘못된 관심도 값입니다.');
      }
      previous = key;
      points.add(
        GoogleTrendsPoint(month: month, value: value.toInt(), isPartial: partial as bool?),
      );
    }
    if (points.first.month != DateTime.utc(2009, 1)) {
      throw const FormatException('전체 기록의 시작 월이 다릅니다.');
    }
    return GoogleTrendsHistoryModel(
      region: region,
      points: List.unmodifiable(points),
      collectedAt: collected.toDate(),
      requestedEnd: end,
      fromCache: fromCache,
    );
  }
}
