import 'package:btc_horizon/providers/usdt_premium_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsdtPremiumCard extends ConsumerWidget {
  const UsdtPremiumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdtPremiumAsync = ref.watch(usdtPremiumProvider);
    return usdtPremiumAsync.when(
      data: (model) {
        return Card(
          color: Colors.brown,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 20),
              child: Column(
                children: [
                  Text("환율 : ${model.usdKrwRate.toStringAsFixed(0)}원"),
                  SizedBox(height: 10),
                  Text("업비트 테더 : ${model.upbitUsdtPrice.toStringAsFixed(0)}원"),
                  Text("빗썸 테더 : ${model.bithumbUsdtPrice.toStringAsFixed(0)}원"),
                  SizedBox(height: 10),
                  Text("테더 프리미엄 : ${model.premiumPercent.toStringAsFixed(2)}%"),
                ],
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) => Text("Error: $error"),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
