import 'package:flutter/material.dart';
import 'snapshot_item.dart';

class MarketSnapshotBar extends StatelessWidget {
  const MarketSnapshotBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TODO: Replace dummy values with provider data.
        Expanded(
          child: SnapshotItem(
            label: 'BTC/USDT',
            value: '\$64,000',
            logo: Image.asset('assets/logos/bitcoin_logo.png', width: 40, height: 40),
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '환율',
            value: '1,530원',
            logo: Image.asset('assets/logos/dollar_logo.png', width: 40, height: 40),
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '테더 김프',
            value: '-1.14%',
            logo: Image.asset('assets/logos/usdt_logo.png', width: 40, height: 40),
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '업비트 테더',
            value: '1,513원',
            logo: Image.asset('assets/logos/upbit_logo.png', width: 40, height: 40),
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '빗썸 테더',
            value: '1,512원',
            logo: Image.asset('assets/logos/bithumb_logo.png', width: 40, height: 40),
          ),
        ),
      ],
    );
  }
}
