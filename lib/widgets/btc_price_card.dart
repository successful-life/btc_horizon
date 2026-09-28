import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:btc_horizon/providers/binance_price_provider.dart';
import 'package:btc_horizon/enums/binance_symbol.dart';

class BtcPriceCard extends ConsumerWidget {
  static final NumberFormat _numberFormatBTC = NumberFormat('#,##0.00');

  static const Color _primaryTextColor = Color(0xFF172033);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const Color _liveColor = Color(0xFF16805D);

  const BtcPriceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(binancePriceProvider(BinanceSymbol.btcusdt));

    final Widget priceContent;
    final String statusLabel;
    final Color statusColor;

    if (btcPriceAsync.hasError) {
      statusLabel = '수신 오류';
      statusColor = _secondaryTextColor;

      priceContent = const Text(
        '비트코인 가격을 불러오지 못했습니다.',
        style: TextStyle(fontSize: 13, color: _secondaryTextColor),
      );
    } else if (btcPriceAsync.isLoading) {
      statusLabel = '수신 대기';
      statusColor = _secondaryTextColor;

      priceContent = const Text(
        '비트코인 가격 불러오는 중...',
        style: TextStyle(fontSize: 13, color: _secondaryTextColor),
      );
    } else {
      statusLabel = '실시간';
      statusColor = _liveColor;

      final btcPrice = btcPriceAsync.requireValue;

      priceContent = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _numberFormatBTC.format(btcPrice),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'USDT',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _secondaryTextColor),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/logos/bitcoin_logo.png', width: 40, height: 40),
              const SizedBox(width: 10),

              // 제목이 남은 너비를 사용하고 상태 표시는 오른쪽에 둡니다.
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '비트코인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _primaryTextColor,
                      ),
                    ),
                    Text(
                      'BTC/USDT · Binance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              _buildStatusIndicator(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),

          // 상태가 바뀌어도 가격 영역의 최소 높이를 유지합니다.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Align(alignment: Alignment.centerLeft, child: priceContent),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
