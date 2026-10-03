import 'dart:convert';

import 'package:btc_horizon/models/mvrv_history_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class KoteMvrvService {
  Future<MvrvHistoryModel> fetchMvrvHistory() async {
    final apiKey = dotenv.env['KOTE_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('KOTE_API_KEY가 설정되지 않았습니다.');
    }

    final uri = Uri.https('kotecharts.com', '/api/v1/public/charts/mvrv-z-score', {
      // 원본 조회 범위와 차트 표시 범위 구분
      'from': '2010-01-01',
      'granularity': 'day',
      'includePartial': 'false',
    });

    final response = await http
        .get(uri, headers: {'X-API-Key': apiKey, 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('MVRV 데이터 요청 실패: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw const FormatException('MVRV API 응답이 올바르지 않습니다.');
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException('MVRV 데이터 영역이 없습니다.');
    }

    return MvrvHistoryModel.fromJson(data);
  }
}
