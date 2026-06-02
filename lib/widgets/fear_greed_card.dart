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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final fearGreedService = FearGreedService();
    final result = await fearGreedService.fetchFearGreed(limit: 1);

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
    return Card(
      color: Colors.grey,
      child: Column(
        children: [
          /*
          Text('Today\'s Fear & Greed Index', style: TextStyle(fontSize: 16, color: Colors.red)),
          Text('${items.first.value}', style: TextStyle(fontSize: 16, color: Colors.red)),
          Text(
            items.first.valueClassification,
            style: TextStyle(color: _getFearGreedColor(items.first.valueClassification)),
          ),*/
          CryptoCard(
            title: 'Fear & Greed Inedx',
            value: items.first.value.toString(),
            subtitle: items.first.valueClassification,
            icon: Icons.psychology,
            bgColor: Colors.cyan,
          ),
        ],
      ),
    );
  }
}
