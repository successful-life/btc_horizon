import 'package:btc_horizon/enums/binance_symbol.dart';
import 'package:btc_horizon/services/binance_socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final binancePriceProvider = StreamProvider.family<double, BinanceSymbol>((ref, symbol) {
  final service = BinanceSocketService(symbol: symbol.webSocket);

  ref.onDispose(() {
    service.dispose();
  });

  return service.getPriceStream();
});
