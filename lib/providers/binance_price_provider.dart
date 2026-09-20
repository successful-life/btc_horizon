import 'package:btc_horizon/enums/binance_symbol.dart';
import 'package:btc_horizon/services/binance_socket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final binanceSocketServiceProvider = Provider.family<BinanceSocketService, BinanceSymbol>((
  ref,
  symbol,
) {
  final service = BinanceSocketService(
    symbol: symbol.webSocket,
    onLog: kDebugMode ? (message) => debugPrint(message) : null,
  );
  ref.onDispose(service.dispose);
  return service;
});

final binancePriceProvider = StreamProvider.family<double, BinanceSymbol>((ref, symbol) {
  final service = ref.watch(binanceSocketServiceProvider(symbol));
  return service.getPriceStream();
}, retry: (_, _) => null); // 재연결 시점은 소켓 서비스에서 관리한다.
