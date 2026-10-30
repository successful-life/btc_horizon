import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:btc_horizon/models/mvrv_latest_model.dart';
import 'package:btc_horizon/models/mvrv_history_cache.dart';

/// 문서 한 개를 읽는 동작은 provider에서 전달합니다.
typedef MvrvDocumentLoader = Future<Map<String, dynamic>?> Function(String path);

class FirestoreMvrvService {
  FirestoreMvrvService({required MvrvDocumentLoader loadDocument, DateTime Function()? now})
    : _loadDocument = loadDocument,
      _now = now ?? DateTime.now;

  static const latestPath = 'mvrv_z_score/latest';
  final MvrvDocumentLoader _loadDocument;
  final DateTime Function() _now;

  String? _cachedRevision;
  MvrvHistoryModel? _cachedHistory;
  Future<MvrvHistoryCache>? _inFlight;

  /// latest 문서 한 개에서 최신 확정 기록과 관련 정보를 읽습니다.
  Future<MvrvLatestModel> fetchLatest({required DateTime Function() now}) async {
    final latest = await _loadDocument(latestPath);

    if (latest == null) {
      throw StateError('$latestPath 문서가 없습니다.');
    }

    if (latest['schemaVersion'] != 1 || latest['isDemo'] != false) {
      throw const FormatException('MVRV 저장 형식 또는 실제 데이터 여부를 확인할 수 없습니다.');
    }

    final rawPoint = latest['latestConfirmed'];

    if (rawPoint is! Map) {
      throw const FormatException('latestConfirmed가 없습니다. 서버 수집 결과를 확인해 주세요.');
    }

    final source = latest['source'];
    final revision = latest['revision'];

    if (source is! String ||
        source.trim().isEmpty ||
        revision is! String ||
        revision.trim().isEmpty) {
      throw const FormatException('MVRV 출처 또는 데이터 버전이 없습니다.');
    }

    // 기존 모델의 날짜·숫자 검증을 재사용합니다.
    final parsed = MvrvHistoryModel.fromJson({
      'asOf': latest['asOf'],
      'completeThrough': latest['completeThrough'],
      'source': source,
      'series': [Map<String, dynamic>.from(rawPoint)],
    });

    final point = parsed.points.single;

    if (parsed.completeThrough.isAfter(parsed.asOfDate) ||
        point.date.isAfter(parsed.completeThrough)) {
      throw const FormatException('최신 MVRV 기록이 확정 날짜 범위를 벗어났습니다.');
    }

    // provider에서 Timestamp → DateTime으로 변환한 값입니다.
    final collectedAt = latest['collectedAt'];

    if (collectedAt is! DateTime) {
      throw const FormatException('MVRV 수집 시각이 없거나 형식이 올바르지 않습니다.');
    }

    return MvrvLatestModel(
      latestConfirmed: point,
      asOfDate: parsed.asOfDate,
      completeThrough: parsed.completeThrough,
      collectedAt: collectedAt.toUtc(),
      checkedAt: now().toUtc(),
      revision: revision,
      source: source,
    );
  }

  /// 기기 저장본을 메모리에 연결합니다. 서버 확인 시각은 바꾸지 않습니다.
  void seedHistoryCache(MvrvHistoryCache snapshot) {
    if (_cachedHistory != null || _inFlight != null) return;
    _cachedRevision = snapshot.revision;
    _cachedHistory = snapshot.history;
  }

  /// 기존 코드에서 차트 기록만 필요할 때 사용할 수 있습니다.
  Future<MvrvHistoryModel> fetchMvrvHistory() async {
    return (await fetchMvrvHistorySnapshot()).history;
  }

  /// 차트 기록과 서버 버전, 확인 시각을 함께 반환합니다.
  Future<MvrvHistoryCache> fetchMvrvHistorySnapshot() async {
    final running = _inFlight;

    if (running != null) {
      return running;
    }

    final task = _fetchConsistentHistory();
    _inFlight = task;

    try {
      return await task;
    } finally {
      _inFlight = null;
    }
  }

  Future<MvrvHistoryCache> _fetchConsistentHistory() async {
    // 서버 갱신과 겹쳐 revision이 섞인 경우에만 한 번 다시 읽습니다.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _readOneRevision();
      } on _RevisionChanged {
        if (attempt == 1) {
          throw StateError('MVRV 데이터가 갱신 중입니다. 잠시 후 다시 확인해 주세요.');
        }
      }
    }
    throw StateError('MVRV 데이터를 읽지 못했습니다.');
  }

  Future<MvrvHistoryCache> _readOneRevision() async {
    final latest = await _loadDocument(latestPath);
    if (latest == null) throw StateError('$latestPath 문서가 없습니다.');
    if (latest['schemaVersion'] != 1) {
      throw const FormatException('지원하지 않는 MVRV 저장 구조입니다.');
    }
    if (latest['isDemo'] != false) {
      throw const FormatException('실제 MVRV 데이터로 확인되지 않았습니다.');
    }
    final revision = latest['revision'];
    final count = latest['pointCount'];
    final rawYears = latest['years'];
    if (revision is! String ||
        revision.isEmpty ||
        count is! int ||
        count <= 0 ||
        rawYears is! List ||
        rawYears.isEmpty ||
        rawYears.length > 100) {
      throw const FormatException('MVRV 데이터의 기본 정보가 올바르지 않습니다.');
    }
    for (final key in ['asOf', 'completeThrough', 'source']) {
      if (latest[key] is! String || (latest[key] as String).isEmpty) {
        throw FormatException('MVRV $key 정보가 없습니다.');
      }
    }
    final years = <int>[];
    for (final year in rawYears) {
      if (year is! int || year < 2010 || year > 2099) {
        throw const FormatException('MVRV 연도 목록이 올바르지 않습니다.');
      }
      years.add(year);
    }
    if (years.toSet().length != years.length) {
      throw const FormatException('MVRV 연도 목록에 중복이 있습니다.');
    }
    years.sort();

    // 앱 실행 중 이미 읽은 같은 revision이면 연도별 문서는 재사용합니다.
    final cached = _cachedHistory;

    final cachedYears = cached?.points.map((point) => point.date.year).toSet();
    final reusable =
        cached != null &&
        _cachedRevision == revision &&
        cached.points.length == count &&
        cached.source == latest['source'] &&
        cached.asOfDate.toIso8601String().substring(0, 10) == latest['asOf'] &&
        cached.completeThrough.toIso8601String().substring(0, 10) == latest['completeThrough'] &&
        cachedYears!.length == years.length &&
        cachedYears.containsAll(years) &&
        (!latest.containsKey('firstDate') ||
            latest['firstDate'] == cached.points.first.date.toIso8601String().substring(0, 10)) &&
        (!latest.containsKey('lastDate') ||
            latest['lastDate'] == cached.points.last.date.toIso8601String().substring(0, 10));

    if (reusable) {
      return MvrvHistoryCache.fromHistory(
        revision: revision,
        lastVerifiedAt: _now(),
        history: cached,
      );
    }

    // 목록 조회 대신 각 문서의 정확한 경로를 지정합니다.
    final annualData = await Future.wait(
      years.map((year) => _loadDocument('$latestPath/years/$year')),
    );
    final series = <Map<String, dynamic>>[];
    for (var i = 0; i < years.length; i++) {
      final year = years[i];
      final data = annualData[i];
      if (data == null) throw StateError('$latestPath/years/$year 문서가 없습니다.');
      if (data['revision'] != revision) throw const _RevisionChanged();
      final rawSeries = data['series'];
      if (rawSeries is! List || rawSeries.isEmpty || rawSeries.length > 366) {
        throw FormatException('$year년 MVRV 기록이 올바르지 않습니다.');
      }
      for (final item in rawSeries) {
        if (item is! Map) {
          throw const FormatException('MVRV 기록 형식이 올바르지 않습니다.');
        }
        final point = Map<String, dynamic>.from(item);
        final day = point['t'];
        if (day is! String || !day.startsWith('$year-')) {
          throw FormatException('$year년 문서에 다른 연도 데이터가 있습니다.');
        }
        if (point['usd'] is! num || point['mvrvZ'] is! num) {
          throw const FormatException('MVRV 가격 또는 점수가 숫자가 아닙니다.');
        }
        series.add(point);
      }
    }
    if (series.length != count) {
      throw const FormatException('MVRV 전체 기록 수가 저장 정보와 다릅니다.');
    }
    // 기존 모델을 재사용하므로 차트와 점수 계산의 입력 형태가 같습니다.
    final history = MvrvHistoryModel.fromJson({
      'asOf': latest['asOf'],
      'completeThrough': latest['completeThrough'],
      'source': latest['source'],
      'series': series,
    });
    if (history.completeThrough.isAfter(history.asOfDate) ||
        history.points.last.date.isAfter(history.asOfDate) ||
        !history.points.any((point) => !point.date.isAfter(history.completeThrough))) {
      throw const FormatException('MVRV 기준일과 시계열 범위가 맞지 않습니다.');
    }
    for (final entry in {
      'firstDate': history.points.first.date,
      'lastDate': history.points.last.date,
    }.entries) {
      if (latest.containsKey(entry.key) &&
          latest[entry.key] != entry.value.toIso8601String().substring(0, 10)) {
        throw FormatException('MVRV ${entry.key} 정보와 실제 기록이 다릅니다.');
      }
    }
    final snapshot = MvrvHistoryCache.fromHistory(
      revision: revision,
      lastVerifiedAt: _now(),
      history: history,
    );

    _cachedRevision = revision;
    _cachedHistory = history;

    return snapshot;
  }
}

class _RevisionChanged implements Exception {
  const _RevisionChanged();
}
