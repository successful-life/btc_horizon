import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/funding_rate_model.dart';
import 'package:btc_horizon/services/funding_rate_service.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fundingRateServiceProvider = Provider<FundingRateService>((ref) {
  return FundingRateService();
});

final fundingRateProvider = FutureProvider<FundingRateModel>((ref) {
  final service = ref.read(fundingRateServiceProvider);
  return fetchWithRefresh(
    ref: ref,
    fetch: service.fetchFundingRate,
    refreshAfter: kFundingRefreshInterval,
  );
}, retry: disableAutomaticRetry);
