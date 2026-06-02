import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:btc_horizon/models/fear_greed_model.dart';

class FearGreedService {
  static const String _baseUrl = 'https://api.alternative.me/fng';

  Future<List<FearGreedModel>> fetchFearGreed({int limit = 1}) async {
    final uri = Uri.parse('$_baseUrl/?limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> dataList = json['data'];

      return dataList.map((item) => FearGreedModel.fromJson(item)).toList();
    } else {
      throw Exception('Fear & Greed index 요청 실패');
    }
  }
}
