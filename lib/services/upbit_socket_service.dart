import 'package:btc_horizon/services/ticker_socket_service.dart';

class UpbitSocketService extends TickerSocketService {
  UpbitSocketService({
    required super.market,
    super.connect,
    super.now,
    super.onLog,
    super.connectTimeout,
    super.heartbeatInterval,
    super.messageTimeout,
    super.priceResponseTimeout,
    super.snapshotRefreshInterval,
  }) : super(
         exchangeName: 'Upbit',
         endpoint: Uri.parse('wss://api.upbit.com/websocket/v1'),
       );
}
