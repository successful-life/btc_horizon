import 'package:flutter/material.dart';
import 'package:btc_horizon/providers/usdt_premium_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TetherOverviewCard extends ConsumerWidget {
  static final NumberFormat _krwFormat = NumberFormat('#,##0');

  static const Color _primaryTextColor = Color(0xFF172033);
  static const Color _secondaryTextColor = Color(0xFF667085);

  static const Color _positiveColor = Color(0xFFD14343);
  static const Color _negativeColor = Color(0xFF2563EB);

  const TetherOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdtPremiumAsync = ref.watch(usdtPremiumProvider);

    final Widget metricsContent;
    final String comparisonText;

    if (usdtPremiumAsync.hasError) {
      metricsContent = const Text(
        '환율 · 테더 정보를 불러오지 못했습니다.',
        style: TextStyle(fontSize: 13, color: _secondaryTextColor),
      );

      comparisonText = '현재 가격과 환율을 비교할 수 없어요.';
    } else if (usdtPremiumAsync.isLoading) {
      metricsContent = const Text(
        '환율 · 테더 정보를 불러오는 중...',
        style: TextStyle(fontSize: 13, color: _secondaryTextColor),
      );

      comparisonText = '가격과 환율을 받아 비교하고 있어요.';
    } else {
      final model = usdtPremiumAsync.requireValue;

      // 화면에 표시되는 소수 둘째 자리 값을 기준으로
      // 부호와 색상을 결정합니다.
      final displayedPremium = double.parse(model.premiumPercent.toStringAsFixed(2));

      final Color premiumColor;
      final String premiumText;

      if (displayedPremium > 0) {
        premiumColor = _positiveColor;
        premiumText = '+${displayedPremium.toStringAsFixed(2)}%';
      } else if (displayedPremium < 0) {
        premiumColor = _negativeColor;
        premiumText = '${displayedPremium.toStringAsFixed(2)}%';
      } else {
        premiumColor = _secondaryTextColor;

        // 아주 작은 음수가 -0.00%로 표시되지 않게 합니다.
        premiumText = '0.00%';
      }

      metricsContent = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildMetricItem(
              label: '달러 환율',
              value: '${_krwFormat.format(model.usdKrwRate)}원',
              valueColor: _primaryTextColor,
            ),
          ),
          Expanded(
            child: _buildMetricItem(
              label: '테더',
              value: '${_krwFormat.format(model.averageUsdtPrice)}원',
              valueColor: _primaryTextColor,
              tooltipMessage:
                  '테더 가격은 업비트와 빗썸 USDT/KRW 가격의 '
                  '단순 평균입니다.\n'
                  '테더 프리미엄도 이 평균 가격을 기준으로 계산합니다.',
            ),
          ),
          Expanded(
            child: _buildMetricItem(label: '테더 프리미엄', value: premiumText, valueColor: premiumColor),
          ),
        ],
      );

      comparisonText = _buildComparisonText(
        averageUsdtPrice: model.averageUsdtPrice,
        usdKrwRate: model.usdKrwRate,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                '원화 · 테더',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 로딩·오류 상태에서도 가격 영역의 최소 높이를 유지합니다.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Align(alignment: Alignment.centerLeft, child: metricsContent),
          ),
          const SizedBox(height: 8),

          // 모든 상태에서 설명 영역을 유지합니다.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                comparisonText,
                style: const TextStyle(fontSize: 12, height: 1.4, color: _secondaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildComparisonText({required double averageUsdtPrice, required double usdKrwRate}) {
    // 화면에서 반올림한 가격이 아닌 원래 값으로 비교합니다.
    final difference = averageUsdtPrice - usdKrwRate;

    if (difference == 0) {
      return '평균 테더 가격이 달러 환율과 같아요.';
    }

    final direction = difference > 0 ? '높아요' : '낮아요';
    final absoluteDifference = difference.abs();

    // 원 단위 반올림으로 "0원 높아요"가 되는 것을 방지합니다.
    if (absoluteDifference < 1) {
      return '평균 테더가 환율보다 1원 미만 $direction.';
    }

    final differenceText = _krwFormat.format(absoluteDifference);

    return '평균 테더가 환율보다 약 $differenceText원 $direction.';
  }
}

Widget _buildMetricItem({
  required String label,
  required String value,
  required Color valueColor,
  String? tooltipMessage,
}) {
  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF667085))),
          ),
          if (tooltipMessage != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 16, color: Color(0xFF667085)),
          ],
        ],
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(color: valueColor, fontSize: 24, fontWeight: FontWeight.w700),
      ),
    ],
  );

  // 설명이 없는 항목은 일반 위젯으로 반환합니다.
  if (tooltipMessage == null) {
    return content;
  }

  // 작은 아이콘뿐 아니라 제목과 값 영역을 탭해도 설명이 열립니다.
  return Tooltip(
    message: tooltipMessage,
    triggerMode: TooltipTriggerMode.tap,
    showDuration: const Duration(seconds: 5),
    preferBelow: false,
    child: content,
  );
}
