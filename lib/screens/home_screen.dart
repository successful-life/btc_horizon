import 'package:btc_horizon/widgets/fear_greed_card.dart';
import 'package:btc_horizon/widgets/funding_rate_card.dart';
import 'package:btc_horizon/widgets/market_snapshot_bar.dart';
import 'package:btc_horizon/widgets/market_temperature.dart';
import 'package:btc_horizon/widgets/mvrv_z_score_card.dart';
import 'package:btc_horizon/widgets/usdt_premium_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        title: const Text('Crypto Cycle Dashboard', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
              child: MarketSnapshotBar(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const MarketTemperature(),
                  const SizedBox(height: 10),
                  const FearGreedCard(),
                  const SizedBox(height: 10),
                  const FundingRateCard(),
                  const SizedBox(height: 10),
                  const MvrvZScoreCard(),
                  const SizedBox(height: 10),
                  const UsdtPremiumCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
