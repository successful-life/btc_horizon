import 'package:btc_horizon/services/bithumb_socket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bithumbSocketServiceProvider =
    Provider.family<BithumbSocketService, String>((ref, market) {
      final service = BithumbSocketService(
        market: market,
        onLog: kDebugMode ? (message) => debugPrint(message) : null,
      );
      ref.onDispose(service.dispose);
      return service;
    });

final bithumbPriceProvider = StreamProvider.family<double, String>((
  ref,
  market,
) {
  final service = ref.watch(bithumbSocketServiceProvider(market));
  return service.getPriceStream();
}, retry: (_, _) => null); // 재연결 시점은 소켓 서비스에서 관리한다.
