import 'package:btc_horizon/services/upbit_socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final upbitPriceProvider = StreamProvider.family<double, String>((ref, market) {
  final service = UpbitSocketService(market: market);

  ref.onDispose(() {
    service.dispose();
  });

  return service.getPriceStream();
});
