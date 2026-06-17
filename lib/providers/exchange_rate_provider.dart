import 'package:btc_horizon/models/exchange_rate_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/services/exchange_rate_service.dart';

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

final exchangeRateProvider = FutureProvider<ExchangeRateModel>((ref) async {
  final service = ref.read(exchangeRateServiceProvider);
  final result = await service.fetchExchangeRate();
  return result;
});
