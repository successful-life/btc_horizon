import 'dart:convert';
import 'package:btc_horizon/models/exchange_rate_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const _baseUrl = 'https://v6.exchangerate-api.com/v6/';
  final apiKey = dotenv.env['EXCHANGE_RATE_API_KEY'];

  Future<ExchangeRateModel> fetchExchangeRate() async {
    final uri = Uri.parse('$_baseUrl$apiKey/latest/USD');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return ExchangeRateModel.fromJson(json);
    } else {
      throw Exception('Exchange Rate 요청 실패');
    }
  }
}
