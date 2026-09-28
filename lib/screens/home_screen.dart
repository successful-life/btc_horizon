import 'package:btc_horizon/widgets/cycle_indicator_section.dart';
import 'package:btc_horizon/widgets/btc_price_card.dart';
import 'package:btc_horizon/widgets/cycle_position.dart';
import 'package:btc_horizon/widgets/tether_overview_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F4F8),
        title: const Text(
          'BTC Horizon',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const BtcPriceCard(),
            const SizedBox(height: 16),
            const TetherOverviewCard(),
            const SizedBox(height: 16),
            const CyclePosition(),
            const SizedBox(height: 16),
            const CycleIndicatorSection(),
          ],
        ),
      ),
    );
  }
}
