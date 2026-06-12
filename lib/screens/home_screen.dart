import 'package:btc_horizon/widgets/btc_price_card.dart';
import 'package:btc_horizon/widgets/fear_greed_card.dart';
import 'package:btc_horizon/widgets/funding_rate_card.dart';
import 'package:btc_horizon/widgets/market_temperature.dart';
import 'package:btc_horizon/widgets/mvrv_z_score_card.dart';
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
        child: Column(
          children: [
            MarketTemperature(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  const SizedBox(height: 10),
                  FearGreedCard(),
                  const SizedBox(height: 10),
                  BtcPriceCard(),
                  const SizedBox(height: 10),
                  FundingRateCard(),
                  const SizedBox(height: 10),
                  MvrvZScoreCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
