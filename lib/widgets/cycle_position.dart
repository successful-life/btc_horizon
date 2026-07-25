import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cycle_position_provider.dart';

class CyclePosition extends ConsumerWidget {
  const CyclePosition({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclePosition = ref.watch(cyclePositionProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(cyclePosition.title, style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            '${cyclePosition.score.toStringAsFixed(1)} / 100',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            cyclePosition.description,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
