import 'package:btc_horizon/services/ticker_socket_service.dart';

class BithumbSocketService extends TickerSocketService {
  BithumbSocketService({
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
         exchangeName: 'Bithumb',
         endpoint: Uri.parse('wss://ws-api.bithumb.com/websocket/v1'),
       );
}
