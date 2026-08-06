import 'package:btc_horizon/enums/binance_interval.dart';
import 'package:btc_horizon/enums/binance_symbol.dart';

class BinanceKlineRequestModel {
  final BinanceSymbol symbol;
  final BinanceKlineInterval interval;
  final int limit;

  const BinanceKlineRequestModel({
    required this.symbol,
    required this.interval,
    required this.limit,
  });
}
