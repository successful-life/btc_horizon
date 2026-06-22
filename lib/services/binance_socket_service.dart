import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class BinanceSocketService {
  static const _baseUrl = 'wss://stream.binance.com:9443';
  static const _streamType = 'miniTicker';
  final String symbol; // ex) btcusdt
  late final WebSocketChannel channel;

  BinanceSocketService({required this.symbol}) {
    channel = WebSocketChannel.connect(Uri.parse('$_baseUrl/ws/$symbol@$_streamType'));
  }

  Stream<double> getPriceStream() {
    return channel.stream.map((data) {
      final json = jsonDecode(data);
      return double.parse(json['c']);
    });
  }

  void dispose() {
    channel.sink.close();
  }
}
