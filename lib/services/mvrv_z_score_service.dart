import 'dart:convert';
import 'package:btc_horizon/models/mvrv_z_score_model.dart';
import 'package:http/http.dart' as http;

class MvrvZScoreService {
  static const _baseUrl = 'https://api.bitcoin-data.com/v1/mvrv-zscore/last';

  Future<MvrvZScoreModel> fetchMvrvZScore() async {
    final uri = Uri.parse(_baseUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return MvrvZScoreModel.fromJson(json);
    } else {
      throw Exception('Mvrv Z Score 요청 실패');
    }
  }
}
