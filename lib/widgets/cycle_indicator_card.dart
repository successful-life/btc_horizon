import 'package:flutter/material.dart';

class CycleIndicatorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String scoreText;
  final Color valueColor;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const CycleIndicatorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.scoreText,
    required this.valueColor,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 아이콘
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 5),

                  // 제목
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // 점수
              Row(
                children: [
                  Text(
                    scoreText,
                    style: TextStyle(color: valueColor, fontSize: 28, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(' / 100', style: TextStyle(color: Colors.black, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 5),
              const Text('자세히 보기', maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
