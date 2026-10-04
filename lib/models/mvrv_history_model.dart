class MvrvHistoryModel {
  final DateTime asOfDate;
  final DateTime completeThrough;
  final String source;
  final List<MvrvHistoryPointModel> points;

  MvrvHistoryModel({
    required this.asOfDate,
    required this.completeThrough,
    required this.source,
    required List<MvrvHistoryPointModel> points,
  }) : points = List.unmodifiable(points);

  factory MvrvHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'];

    if (rawSeries is! List) {
      throw const FormatException('MVRV 시계열 형식이 올바르지 않습니다.');
    }

    final points = rawSeries.map((item) {
      return MvrvHistoryPointModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    if (points.isEmpty) {
      throw const FormatException('MVRV 데이터가 비어 있습니다.');
    }

    // 같은 날짜가 중복되면 임의로 하나를 선택하지 않습니다.
    for (var i = 1; i < points.length; i++) {
      if (points[i].date == points[i - 1].date) {
        throw const FormatException('MVRV 데이터에 중복 날짜가 있습니다.');
      }
    }

    return MvrvHistoryModel(
      asOfDate: _parseDailyDate(json['asOf']),
      completeThrough: _parseDailyDate(json['completeThrough']),
      source: json['source'] as String? ?? '',
      points: points,
    );
  }
}

class MvrvHistoryPointModel {
  final DateTime date;
  final double btcPriceUsd;
  final double mvrvZScore;

  const MvrvHistoryPointModel({
    required this.date,
    required this.btcPriceUsd,
    required this.mvrvZScore,
  });

  factory MvrvHistoryPointModel.fromJson(Map<String, dynamic> json) {
    final price = (json['usd'] as num).toDouble();
    final zScore = (json['mvrvZ'] as num).toDouble();

    if (!price.isFinite || price <= 0 || !zScore.isFinite) {
      throw const FormatException('MVRV 데이터에 유효하지 않은 값이 있습니다.');
    }

    return MvrvHistoryPointModel(
      date: _parseDailyDate(json['t']),
      btcPriceUsd: price,
      mvrvZScore: zScore,
    );
  }
}

DateTime _parseDailyDate(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('일별 데이터 날짜 형식이 올바르지 않습니다.');
  }

  final date = DateTime.tryParse('${value}T00:00:00Z');

  // DateTime이 잘못된 날짜를 다음 달로 보정하는 경우도 검사합니다.
  if (date == null || date.toIso8601String().substring(0, 10) != value) {
    throw const FormatException('유효하지 않은 날짜입니다.');
  }

  return date;
}
