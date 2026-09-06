import 'package:btc_horizon/enums/bitstamp_symbol.dart';
import 'package:btc_horizon/models/bitstamp_ohlc_model.dart';
import 'package:btc_horizon/services/bitstamp_ohlc_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bitstampOhlcServiceProvider = Provider<BitstampOhlcService>((ref) {
  return BitstampOhlcService();
});

final bitstampOhlcProvider = FutureProvider.family<List<BitstampOhlcModel>, BitstampSymbol>((
  ref,
  symbol,
) {
  final service = ref.read(bitstampOhlcServiceProvider);
  const dailyStep = 86400;

  return service.fetchAllOhlc(symbol: symbol, step: dailyStep, startTime: DateTime(2011, 8, 18));
});
