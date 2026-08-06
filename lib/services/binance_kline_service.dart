import 'dart:convert';

import 'package:btc_horizon/models/binance_kline_model.dart';
import 'package:http/http.dart' as http;

class BinanceKlineService {
  static const String _baseUrl = 'https://api.binance.com/api/v3/klines';

  Future<List<BinanceKlineModel>> fetchKlines({
    required String symbol,
    required String interval,
    int limit = 100,
  }) async {
    final uri = Uri.parse('$_baseUrl?symbol=$symbol&limit=$limit&interval=$interval');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((item) => BinanceKlineModel.fromJson(item as List<dynamic>)).toList();
    } else {
      throw Exception('바이낸스 kline을 불러오는 데 실패했습니다.');
    }
  }
}
