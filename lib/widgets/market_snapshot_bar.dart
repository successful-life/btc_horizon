import 'package:btc_horizon/providers/binance_price_provider.dart';
import 'package:btc_horizon/providers/usdt_premium_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'snapshot_item.dart';
import 'package:intl/intl.dart';

class MarketSnapshotBar extends ConsumerWidget {
  static final NumberFormat _numberFormatBTC = NumberFormat('#,##0.00');
  static final NumberFormat _numberFormatUSD = NumberFormat('#,##0');

  const MarketSnapshotBar({super.key});

  Widget _logo(String path) {
    return Image.asset(path, width: 40, height: 40);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(binancePriceProvider("btcusdt"));
    final usdtPremiumAsync = ref.watch(usdtPremiumProvider);

    if (btcPriceAsync.isLoading || usdtPremiumAsync.isLoading) {
      return const SizedBox(height: 80, child: Center(child: Text("시장 데이터 로딩 중...")));
    }

    if (btcPriceAsync.hasError || usdtPremiumAsync.hasError) {
      return const SizedBox(height: 80, child: Center(child: Text("시장 데이터 오류")));
    }

    final model = usdtPremiumAsync.requireValue;
    final btcPrice = btcPriceAsync.requireValue;

    return Row(
      children: [
        Expanded(
          child: SnapshotItem(
            label: 'BTC/USDT',
            value: '\$${_numberFormatBTC.format(btcPrice)}',
            logo: _logo('assets/logos/bitcoin_logo.png'),
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '환율',
            value: '${_numberFormatUSD.format(model.usdKrwRate)}원',
            logo: _logo('assets/logos/dollar_logo.png'),
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '테더 김프',
            value: '${model.premiumPercent.toStringAsFixed(2)}%',
            logo: _logo('assets/logos/usdt_logo.png'),
            valueColor: model.premiumPercent >= 0 ? Colors.green : Colors.red,
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '업비트 테더',
            value: '${_numberFormatUSD.format(model.upbitUsdtPrice)}원',
            logo: _logo('assets/logos/upbit_logo.png'),
          ),
        ),
        Expanded(
          child: SnapshotItem(
            label: '빗썸 테더',
            value: '${_numberFormatUSD.format(model.bithumbUsdtPrice)}원',
            logo: _logo('assets/logos/bithumb_logo.png'),
          ),
        ),
      ],
    );
  }
}
