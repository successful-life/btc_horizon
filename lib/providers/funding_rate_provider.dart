import 'package:btc_horizon/models/funding_rate_model.dart';
import 'package:btc_horizon/services/funding_rate_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fundingRateServiceProvider = Provider<FundingRateService>((ref) {
  return FundingRateService();
});

final fundingRateProvider = FutureProvider<FundingRateModel>((ref) async {
  final service = ref.read(fundingRateServiceProvider);
  final result = await service.fetchFundingRate();

  return result;
});
