import 'package:btc_horizon/models/funding_rate_model.dart';
import 'package:btc_horizon/services/funding_rate_service.dart';
import 'package:btc_horizon/widgets/crypto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/providers/funding_rate_provider.dart';

class FundingRateCard extends ConsumerWidget {
  const FundingRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundingRateAsyncValue = ref.watch(fundingRateProvider);

    return fundingRateAsyncValue.when(
      data: (fundingRateModel) {
        return CryptoCard(
          title: '펀딩비',
          value: '${(fundingRateModel.lastFundingRate * 100).toStringAsFixed(4)}%',
          subtitle: '바이낸스 선물',
          icon: Icons.currency_exchange,
          bgColor: Colors.purple,
        );
      },

      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text("에러 발생: $error"),
    );
  }
}
