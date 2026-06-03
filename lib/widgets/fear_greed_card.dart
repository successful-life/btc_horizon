import 'package:btc_horizon/models/fear_greed_model.dart';
import 'package:btc_horizon/services/fear_greed_service.dart';
import 'package:btc_horizon/widgets/crypto_card.dart';
import 'package:flutter/material.dart';

class FearGreedCard extends StatefulWidget {
  const FearGreedCard({super.key});

  @override
  State<FearGreedCard> createState() => _FearGreedCardState();
}

class _FearGreedCardState extends State<FearGreedCard> {
  List<FearGreedModel> items = [];
  bool isLoading = true;
  final FearGreedService fearGreedService = FearGreedService();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final result = await fearGreedService.fetchFearGreed(limit: 1);

    if (!mounted) return;

    setState(() {
      items = result;
      isLoading = false;
    });
  }

  Color _getFearGreedColor(String classification) {
    return switch (classification) {
      'Extreme Fear' => Colors.red,
      'Fear' => Colors.orange,
      'Neutral' => Colors.yellow,
      'Greed' => Colors.lightGreen,
      'Extreme Greed' => Colors.green,

      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Text('데이터 없음');
    }
    return CryptoCard(
      title: 'Fear & Greed Index',
      value: items.first.value.toString(),
      subtitle: items.first.valueClassification,
      icon: Icons.psychology,
      bgColor: Colors.cyan,
    );
  }
}
