import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_temperature_provider.dart';

class MarketTemperature extends ConsumerWidget {
  const MarketTemperature({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempAsyncValue = ref.watch(marketTemperatureProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
      child: tempAsyncValue.when(
        data: (temperature) {
          String status = switch (temperature) {
            >= 90 => '위험',
            >= 80 => '과열',
            >= 70 => '주의',
            >= 40 => '보통',
            _ => '낮음',
          };

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('시장 온도', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                '${temperature.toStringAsFixed(1)} / 100',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(status, style: const TextStyle(color: Colors.white)),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (error, stack) => Text("에러 발생: $error"),
      ),
    );
  }
}
