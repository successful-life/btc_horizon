import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class UpbitSocketService {
  final String market;
  static const String _baseUrl = 'wss://api.upbit.com/websocket/v1';
  late final WebSocketChannel channel;

  UpbitSocketService({required this.market});

  Stream<double> getPriceStream() {
    channel = WebSocketChannel.connect(Uri.parse(_baseUrl));
    channel.sink.add(
      jsonEncode([
        {"ticket": "test"},
        {
          "type": "ticker",
          "codes": [market],
        },
      ]),
    );
    return channel.stream.map((data) {
      final result = jsonDecode(utf8.decode(data));

      print(result['trade_price']);

      return 0.0;
    });
  }

  void dispose() {
    channel.sink.close();
  }
}
