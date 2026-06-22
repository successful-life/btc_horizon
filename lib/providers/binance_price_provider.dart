import 'package:btc_horizon/services/binance_socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final binancePriceProvider = StreamProvider.family<double, String>((ref, symbol) {
  final service = BinanceSocketService(symbol: symbol);

  ref.onDispose(() {
    service.dispose();
  });

  return service.getPriceStream();
});
