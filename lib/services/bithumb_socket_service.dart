import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class BithumbSocketService {
  final String market;
  static const String _baseUrl = 'wss://ws-api.bithumb.com/websocket/v1';
  late final WebSocketChannel channel;

  BithumbSocketService({required this.market});

  Stream<double> getPriceStream() {
    channel = WebSocketChannel.connect(Uri.parse(_baseUrl));
    channel.sink.add(
      jsonEncode([
        {"ticket": "test example"},
        {
          "type": "ticker",
          "codes": [market],
        },
        {"format": "DEFAULT"},
      ]),
    );

    return channel.stream.map((data) {
      final result = jsonDecode(utf8.decode(data));

      return (result['trade_price'] as num).toDouble();
    });
  }

  void dispose() {
    channel.sink.close();
  }
}
