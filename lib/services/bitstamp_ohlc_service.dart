import 'dart:convert';

import 'package:btc_horizon/enums/bitstamp_symbol.dart';
import 'package:btc_horizon/models/bitstamp_ohlc_model.dart';
import 'package:http/http.dart' as http;

class BitstampOhlcService {
  static const String _baseUrl = 'https://www.bitstamp.net/api/v2/ohlc';

  Future<List<BitstampOhlcModel>> fetchOhlc({
    required BitstampSymbol symbol,
    required int step,
    int limit = 100,
    int? start,
    bool excludeCurrentCandle = true, // 아직 완성되지 않은 현재 일봉 제외
  }) async {
    final queryParameters = {
      'step': step.toString(),
      'limit': limit.toString(),
      if (start != null) 'start': start.toString(),
      'exclude_current_candle': excludeCurrentCandle.toString(),
    };

    final uri = Uri.parse('$_baseUrl/${symbol.value}/').replace(queryParameters: queryParameters);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Bitstamp OHLC 요청 실패: ${response.statusCode}');
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    final data = json['data'] as Map<String, dynamic>;
    final ohlcList = data['ohlc'] as List;

    return ohlcList.map((e) => BitstampOhlcModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BitstampOhlcModel>> fetchAllOhlc({
    required BitstampSymbol symbol,
    required int step,
    required DateTime startTime,
  }) async {
    const limit = 1000;

    final allOhlc = <BitstampOhlcModel>[];

    var start = startTime.millisecondsSinceEpoch ~/ 1000;

    while (true) {
      final batch = await fetchOhlc(
        symbol: symbol,
        step: step,
        limit: limit,
        start: start,
        excludeCurrentCandle: true,
      );

      if (batch.isEmpty) {
        break;
      }

      batch.sort((a, b) => a.openTime.compareTo(b.openTime));

      allOhlc.addAll(batch);

      final lastOpenTime = batch.last.openTime.millisecondsSinceEpoch ~/ 1000;

      final nextStart = lastOpenTime + step;

      // 무한 반복 방어
      if (nextStart <= start) {
        throw StateError('Bitstamp OHLC pagination이 진행되지 않았습니다.');
      }

      start = nextStart;
    }

    return allOhlc;
  }
}
