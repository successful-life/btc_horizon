import 'package:btc_horizon/services/bithumb_socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bithumbPriceProvider = StreamProvider.family<double, String>((ref, market) {
  final service = BithumbSocketService(market: market);

  ref.onDispose(() {
    service.dispose();
  });

  return service.getPriceStream();
});
