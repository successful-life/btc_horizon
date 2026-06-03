import 'dart:convert';

import 'package:btc_horizon/models/funding_rate_model.dart';
import 'package:http/http.dart' as http;

class FundingRateService {
  static const String _baseUrl = 'https://fapi.binance.com';
  static const String _path = '/fapi/v1/premiumIndex?symbol=BTCUSDT';

  Future<FundingRateModel> fetchFundingRate() async {
    final uri = Uri.parse("$_baseUrl$_path");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return FundingRateModel.fromJson(json);
    } else {
      throw Exception('Funding Rate 요청 실패');
    }
  }
}
