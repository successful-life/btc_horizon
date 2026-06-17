import 'package:btc_horizon/widgets/crypto_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/providers/exchange_rate_provider.dart';
import 'package:intl/intl.dart';

class ExchangeRateCard extends ConsumerWidget {
  const ExchangeRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRateAsyncValue = ref.watch(exchangeRateProvider);

    return exchangeRateAsyncValue.when(
      data: (exchangeRateModel) {
        return CryptoCard(
          title: '환율',
          value: exchangeRateModel.krw.toStringAsFixed(0),
          subtitle: '다음 갱신: ${DateFormat('M월 d일 HH:mm').format(exchangeRateModel.nextUpdate)}',
          icon: Icons.currency_exchange,
          bgColor: Colors.brown,
        );
      },
      error: (error, stackTrace) => Text('error : $error'),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
