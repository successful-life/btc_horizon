import 'package:btc_horizon/services/upbit_socket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final upbitSocketServiceProvider = Provider.family<UpbitSocketService, String>((
  ref,
  market,
) {
  final service = UpbitSocketService(
    market: market,
    onLog: kDebugMode ? (message) => debugPrint(message) : null,
  );
  ref.onDispose(service.dispose);
  return service;
});

final upbitPriceProvider = StreamProvider.family<double, String>((ref, market) {
  final service = ref.watch(upbitSocketServiceProvider(market));
  return service.getPriceStream();
}, retry: (_, _) => null); // 재연결 시점은 소켓 서비스에서 관리한다.
