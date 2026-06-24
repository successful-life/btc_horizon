import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cycle_position_provider.dart';

class CyclePosition extends ConsumerWidget {
  const CyclePosition({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclePositionAsync = ref.watch(cyclePositionProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
      child: cyclePositionAsync.when(
        data: (score) {
          final positionLabel = switch (score) {
            >= 81 => '고점 위험',
            >= 61 => '과열 진입',
            >= 41 => '중립 구간',
            >= 21 => '저평가 구간',
            _ => '저점권',
          };

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('시장 사이클 위치', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                '${score.toStringAsFixed(1)} / 100',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                positionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('시장 사이클 위치 데이터 로딩 중...', style: TextStyle(color: Colors.white)),
          ),
        ),
        error: (error, stack) =>
            const Text('시장 사이클 위치 데이터 오류', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
