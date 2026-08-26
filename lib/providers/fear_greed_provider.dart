import 'package:btc_horizon/models/fear_greed_model.dart';
import 'package:btc_horizon/services/fear_greed_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fearGreedServiceProvider = Provider<FearGreedService>((ref) {
  return FearGreedService();
});

final fearGreedProvider = FutureProvider<FearGreedModel>((ref) async {
  final service = ref.read(fearGreedServiceProvider);
  final resultList = await service.fetchFearGreed(limit: 1);

  return resultList.first;
});
