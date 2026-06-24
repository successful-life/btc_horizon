import 'package:btc_horizon/widgets/cycle_indicator_section.dart';
import 'package:btc_horizon/widgets/market_snapshot_bar.dart';
import 'package:btc_horizon/widgets/cycle_position.dart';
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
                  const CyclePosition(),
                  const SizedBox(height: 20),
                  const CycleIndicatorSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
