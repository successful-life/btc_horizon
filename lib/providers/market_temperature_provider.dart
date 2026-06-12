import 'package:btc_horizon/providers/mvrv_z_score_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fear_greed_provider.dart';
import 'funding_rate_provider.dart';

// 1. MVRV 점수 변환 로직
double _getMvrvScore(double mvrv) {
  if (mvrv >= 6.0) return 100.0;
  if (mvrv >= 5.0) return 92.0;
  if (mvrv >= 4.0) return 85.0;
  if (mvrv >= 3.0) return 75.0;
  if (mvrv >= 2.0) return 60.0;
  if (mvrv >= 1.5) return 50.0;
  if (mvrv >= 1.0) return 40.0;
  if (mvrv >= 0.5) return 30.0;
  if (mvrv >= 0.2) return 20.0;
  if (mvrv >= 0.0) return 15.0;
  if (mvrv >= -0.2) return 10.0;
  if (mvrv >= -0.4) return 5.0;
  return 0.0;
}

// 2. 펀딩비 점수 변환 로직
double _getFundingScore(double fundingRate) {
  if (fundingRate >= 0.16) return 20.0;
  if (fundingRate >= 0.14) return 18.0;
  if (fundingRate >= 0.10) return 16.0;
  if (fundingRate >= 0.06) return 14.0;
  if (fundingRate >= 0.03) return 12.0;
  if (fundingRate >= 0.01) return 10.0;
  if (fundingRate >= 0.00) return 8.0;
  if (fundingRate >= -0.01) return 6.0;
  if (fundingRate >= -0.03) return 4.0;
  if (fundingRate >= -0.05) return 2.0;
  return 0.0;
}

// 3. 시장 온도 계산 Provider
final marketTemperatureProvider = FutureProvider<double>((ref) async {
  final fearGreedData = await ref.watch(fearGreedProvider.future);
  final fundingRateData = await ref.watch(fundingRateProvider.future);
  final mvrvZScoreData = await ref.watch(mvrvZScoreProvider.future);

  // 실제 데이터 추출
  double fearGreedValue = fearGreedData.value.toDouble();
  double fundingRateValue = fundingRateData.lastFundingRate;
  double mvrvZScoreValue = mvrvZScoreData.mvrvZScore;

  // 점수 변환 로직 실행
  double mvrvScore = _getMvrvScore(mvrvZScoreValue);
  double fundingScore = _getFundingScore(fundingRateValue);

  // 가중치 합산: 공포&탐욕(40%) + MVRV(55%) + 펀딩비(5%)
  double finalTemperature =
      (fearGreedValue * 0.40) + (mvrvScore * 0.55) + (fundingScore * 5 * 0.05);

  // 온도가 0~100 사이를 벗어나지 않게 고정
  return finalTemperature.clamp(0.0, 100.0);
});
