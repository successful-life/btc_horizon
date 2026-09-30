import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/providers/cycle_position_provider.dart';

class CyclePosition extends ConsumerWidget {
  const CyclePosition({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(cyclePositionProvider);

    final positionLabel = score == null ? '산출 불가' : _getCyclePositionLabel(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: const Tooltip(
                  message:
                      '가치평가·사이클 타이밍·추세·심리 지표를 '
                      '가중 합산한 점수입니다.\n'
                      '0에 가까울수록 저점 쪽, '
                      '100에 가까울수록 고점 쪽을 나타냅니다.',
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: Duration(seconds: 5),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            '비트코인 사이클',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF172033),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.info_outline, size: 18, color: Color(0xFF667085)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: score == null ? const Color(0xFFF2F4F7) : const Color(0xFFEBF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  positionLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: score == null ? const Color(0xFF667085) : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 서로 다른 글자 크기도 같은 기준선에 맞춰 표시합니다.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: score == null ? '—' : score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
                const TextSpan(
                  text: ' / 100',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _CyclePositionScale(score: score),
        ],
      ),
    );
  }
}

class _CyclePositionScale extends StatelessWidget {
  final double? score;

  const _CyclePositionScale({required this.score});

  static const double _markerSize = 20;
  static const double _trackHeight = 10;

  // 10점 간격의 시각적 눈금입니다.
  // 상태 배지의 분류 기준과는 별개입니다.
  static const List<Color> _segmentColors = [
    Color(0xFF559BF0),
    Color(0xFF70ACF3),
    Color(0xFF8ABBF2),
    Color(0xFFA7C9ED),
    Color(0xFFC0CEDC),
    Color(0xFFD1D2C8),
    Color(0xFFE0D5AE),
    Color(0xFFEED58C),
    Color(0xFFF4CD68),
    Color(0xFFF7C449),
  ];

  @override
  Widget build(BuildContext context) {
    final currentScore = score;

    // 표시점이 눈금 밖으로 나가지 않도록 위치만 제한합니다.
    final progress = currentScore == null ? null : (currentScore / 100).clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // 양끝에서도 표시점 전체가 카드 안에 들어오도록
            // 눈금의 시작과 끝을 표시점 반지름만큼 안쪽에 둡니다.
            final trackWidth = constraints.maxWidth - _markerSize;

            return SizedBox(
              width: double.infinity,
              height: _markerSize,
              child: Stack(
                children: [
                  Positioned(
                    left: _markerSize / 2,
                    right: _markerSize / 2,
                    top: (_markerSize - _trackHeight) / 2,
                    height: _trackHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_trackHeight / 2),
                      child: Row(
                        children: [
                          for (var index = 0; index < _segmentColors.length; index++) ...[
                            if (index > 0) const SizedBox(width: 1),
                            Expanded(
                              child: ColoredBox(
                                color: currentScore == null
                                    ? const Color(0xFFE4E7EC)
                                    : _segmentColors[index],
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 점수가 없으면 임의의 위치를 표시하지 않습니다.
                  if (progress != null)
                    Positioned(
                      left: trackWidth * progress,
                      top: 0,
                      width: _markerSize,
                      height: _markerSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF172033),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: _markerSize / 2),
          child: Row(
            children: [
              Expanded(
                child: Text('0 · 저점권', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
              ),
              Expanded(
                child: Text(
                  '고점권 · 100',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _getCyclePositionLabel(double score) {
  if (score < 20) {
    return '저점권';
  }

  if (score < 40) {
    return '저점권 인접';
  }

  if (score < 60) {
    return '중립';
  }

  if (score < 80) {
    return '고점권 인접';
  }

  return '고점권';
}
