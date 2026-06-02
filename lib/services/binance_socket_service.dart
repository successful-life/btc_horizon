import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class BinanceSocketService {
  static const _baseUrl = 'wss://stream.binance.com:9443';
  static const _streamPath = '/ws/btcusdt@miniTicker';
  final channel = WebSocketChannel.connect(Uri.parse('$_baseUrl$_streamPath'));

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
