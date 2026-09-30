import 'package:flutter/material.dart';

class CycleIndicatorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double? score;
  final Color iconColor;
  final VoidCallback onTap;

  const CycleIndicatorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.score,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentScore = score;
    final scoreText = currentScore?.round().toString() ?? '—';

    // 각 행의 점수 영역을 같은 너비로 맞춥니다.
    // 글자 확대 설정에 따라 이 영역도 넓어집니다.
    final scoreWidth = MediaQuery.textScalerOf(context).scale(26) * 2.2;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // 카테고리 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),

              // 제목과 점수 위치 눈금
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _IndicatorScoreScale(score: currentScore),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 네 행 모두 같은 위치에 점수를 표시합니다.
              SizedBox(
                width: scoreWidth,
                child: Text(
                  scoreText,
                  textAlign: TextAlign.right,
                  semanticsLabel: currentScore == null ? '점수 산출 불가' : '${currentScore.round()}점',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: currentScore == null ? const Color(0xFF667085) : const Color(0xFF172033),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF667085)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorScoreScale extends StatelessWidget {
  final double? score;

  const _IndicatorScoreScale({required this.score});

  static const double _markerSize = 12;
  static const double _trackHeight = 3;

  @override
  Widget build(BuildContext context) {
    final currentScore = score;

    final progress = currentScore == null ? null : (currentScore / 100).clamp(0.0, 1.0).toDouble();

    // 점수는 별도 Text에서 읽으므로 장식용 눈금은 제외합니다.
    return ExcludeSemantics(
      child: SizedBox(
        width: double.infinity,
        height: _markerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 양끝에서 표시점이 잘리지 않도록 여유를 둡니다.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _markerSize / 2),
              child: Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF3),
                  borderRadius: BorderRadius.circular(_trackHeight / 2),
                ),
              ),
            ),

            // 점수가 없으면 회색 눈금만 유지합니다.
            if (progress != null)
              Align(
                // 0점: -1(왼쪽), 50점: 0(중앙), 100점: 1(오른쪽)
                alignment: Alignment(progress * 2 - 1, 0),
                child: Container(
                  width: _markerSize,
                  height: _markerSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
