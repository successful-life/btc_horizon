import 'package:btc_horizon/widgets/btc_price_card.dart';
import 'package:btc_horizon/widgets/fear_greed_card.dart';
import 'package:btc_horizon/widgets/funding_rate_card.dart';
import 'package:btc_horizon/widgets/market_temperature.dart';
import 'package:flutter/material.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              MarketTemperature(),

              SizedBox(height: 20),
              FearGreedCard(),
              SizedBox(height: 10),
              BtcPriceCard(),
              SizedBox(height: 10),
              FundingRateCard(),
            ],
          ),
        ),
      ),
    );
  }
}
