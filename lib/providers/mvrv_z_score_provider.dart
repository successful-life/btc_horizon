import 'package:btc_horizon/models/mvrv_z_score_model.dart';
import 'package:btc_horizon/services/mvrv_z_score_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mvrvZScoreServiceProvider = Provider<MvrvZScoreService>((ref) {
  return MvrvZScoreService();
});

final mvrvZScoreProvider = FutureProvider<MvrvZScoreModel>((ref) async {
  final service = ref.read(mvrvZScoreServiceProvider);
  final result = await service.fetchMvrvZScore();

  return result;
});
