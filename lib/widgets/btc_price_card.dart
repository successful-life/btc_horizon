import 'package:flutter/material.dart';
import 'package:btc_horizon/services/binance_socket_service.dart';
import 'package:btc_horizon/widgets/crypto_card.dart';

class BtcPriceCard extends StatefulWidget {
  const BtcPriceCard({super.key});

  @override
  State<BtcPriceCard> createState() => _BtcPriceCardState();
}

class _BtcPriceCardState extends State<BtcPriceCard> {
  final BinanceSocketService binanceSocketService = BinanceSocketService();

  late final Stream<double> btcPriceStream;

  double btcPreviousPrice = 0.0;
  double btcNowPrice = 0.0;

  @override
  void initState() {
    super.initState();

    btcPriceStream = binanceSocketService.getPriceStream();
  }

  @override
  void dispose() {
    binanceSocketService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: btcPriceStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('에러 발생');
        }
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        return CryptoCard(
          title: '비트코인 가격',
          value: '${snapshot.data}',
          subtitle: '바이낸스 현물',
          icon: Icons.currency_bitcoin,
          bgColor: Colors.orange.shade400,
        );
      },
    );
  }
}
