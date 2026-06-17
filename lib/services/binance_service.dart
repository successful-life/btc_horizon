import 'dart:convert';
import 'package:btc_horizon/models/coin_price_model.dart';
import 'package:http/http.dart' as http;

class BinanceService {
  // Rest API
  static const String _baseUrl = "https://api.binance.com/api/v3/ticker/price";

  Future<CoinPriceModel> fetchCoinPrice() async {
    final uri = Uri.parse("$_baseUrl?symbol=BTCUSDT");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      return CoinPriceModel.fromJson(json);
    } else {
      throw Exception('Coin Price 요청 실패');
    }
  }
}
