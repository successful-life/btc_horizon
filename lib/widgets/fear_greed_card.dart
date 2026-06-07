import 'package:btc_horizon/models/fear_greed_model.dart';
import 'package:btc_horizon/services/fear_greed_service.dart';
import 'package:btc_horizon/widgets/crypto_card.dart';
import 'package:flutter/material.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FearGreedCard extends ConsumerWidget {
  const FearGreedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fearGreedAsyncValue = ref.watch(fearGreedProvider);

    return fearGreedAsyncValue.when(
      data: (fearGreedModel) {
        return CryptoCard(
          title: 'Fear & Greed Index',
          value: fearGreedModel.value.toString(),
          subtitle: fearGreedModel.valueClassification,
          icon: Icons.psychology,
          bgColor: Colors.cyan,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Text('데이터를 불러오지 못했습니다.'),
    );
  }
}
