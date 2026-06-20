import 'package:btc_horizon/models/usdt_premium_model.dart';
import 'package:btc_horizon/providers/bithumb_price_provider.dart';
import 'package:btc_horizon/providers/exchange_rate_provider.dart';
import 'package:btc_horizon/providers/ubpit_price_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double _calculatePremiumPercent({required double targetPrice, required double basePrice}) {
  return ((targetPrice - basePrice) / basePrice) * 100;
}

final usdtPremiumProvider = Provider<AsyncValue<UsdtPremiumModel>>((ref) {
  const krwUsdtMarket = "KRW-USDT";

  final upbitUsdtAsync = ref.watch(upbitPriceProvider(krwUsdtMarket));
  final bithumbUsdtAsync = ref.watch(bithumbPriceProvider(krwUsdtMarket));
  final exchangeRateAsync = ref.watch(exchangeRateProvider);

  // 로딩 시
  if (upbitUsdtAsync.isLoading || bithumbUsdtAsync.isLoading || exchangeRateAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // 에러 발생 시
  if (upbitUsdtAsync.hasError) {
    return AsyncValue.error(upbitUsdtAsync.error!, upbitUsdtAsync.stackTrace!);
  }

  if (bithumbUsdtAsync.hasError) {
    return AsyncValue.error(bithumbUsdtAsync.error!, bithumbUsdtAsync.stackTrace!);
  }

  if (exchangeRateAsync.hasError) {
    return AsyncValue.error(exchangeRateAsync.error!, exchangeRateAsync.stackTrace!);
  }

  // 데이터가 존재할 경우
  final upbitUsdtPrice = upbitUsdtAsync.requireValue;
  final bithumbUsdtPrice = bithumbUsdtAsync.requireValue;
  final exchangeRate = exchangeRateAsync.requireValue;

  final usdKrwRate = exchangeRate.krw;
  final averageUsdtPrice = (upbitUsdtPrice + bithumbUsdtPrice) / 2;

  final averageUsdtPremiumPercent = _calculatePremiumPercent(
    targetPrice: averageUsdtPrice,
    basePrice: usdKrwRate,
  );

  return AsyncValue.data(
    UsdtPremiumModel(
      premiumPercent: averageUsdtPremiumPercent,
      upbitUsdtPrice: upbitUsdtPrice,
      bithumbUsdtPrice: bithumbUsdtPrice,
      usdKrwRate: usdKrwRate,
      averageUsdtPrice: averageUsdtPrice,
    ),
  );
});
