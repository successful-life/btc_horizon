import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:btc_horizon/widgets/crypto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MvrvZScoreCard extends ConsumerWidget {
  const MvrvZScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mvrvZScoreAsyncValue = ref.watch(mvrvZScoreProvider);

    return mvrvZScoreAsyncValue.when(
      data: (mvrvZScoreModel) {
        return CryptoCard(
          title: 'MVRV Z SCORE',
          value: mvrvZScoreModel.mvrvZScore.toString(),
          subtitle: DateFormat('yyyy-MM-dd').format(mvrvZScoreModel.timestamp),
          icon: Icons.show_chart,
          bgColor: Colors.lime,
        );
      },
      error: (error, stackTrace) => Text("Error: $error"),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
