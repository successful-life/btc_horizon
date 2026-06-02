import 'dart:async';

import 'package:btc_horizon/models/coin_price_model.dart';
import 'package:btc_horizon/models/fear_greed_model.dart';
import 'package:btc_horizon/services/binance_service.dart';
import 'package:btc_horizon/services/binance_socket_service.dart';
import 'package:btc_horizon/widgets/btc_price_card.dart';
import 'package:btc_horizon/widgets/fear_greed_card.dart';
import 'package:flutter/material.dart';
import 'package:btc_horizon/services/fear_greed_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Card(
          color: Color(0xFF111827),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [FearGreedCard(), BtcPriceCard()],
            ),
          ),
        ),
      ),
    );
  }
}
