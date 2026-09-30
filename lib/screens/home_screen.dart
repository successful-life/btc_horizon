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
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logos/btc_horizon_logo.png',
              width: 40,
              height: 32,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 8),
            const Text(
              'BTC Horizon',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF172033)),
            ),
          ],
        ),
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
            const SizedBox(height: 24),
            const CycleIndicatorSection(),
          ],
        ),
      ),
    );
  }
}
