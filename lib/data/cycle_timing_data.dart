import 'package:btc_horizon/models/halving_cycle_model.dart';

// 반감기 관련 정보
final historicalCycles = List<HalvingCycleModel>.unmodifiable([
  HalvingCycleModel(startDate: DateTime(2012, 11, 28), endDate: DateTime(2016, 7, 9)),
  HalvingCycleModel(startDate: DateTime(2016, 7, 9), endDate: DateTime(2020, 5, 11)),
  HalvingCycleModel(startDate: DateTime(2020, 5, 11), endDate: DateTime(2024, 4, 20)),
]);

final estimatedNextHalvingDate = DateTime(2028, 4, 13);

final currentHalvingCycle = HalvingCycleModel(
  startDate: historicalCycles.last.endDate,
  endDate: estimatedNextHalvingDate,
);

// 고점 및 저점 정보
final btcCycleBottoms = List<DateTime>.unmodifiable([
  DateTime(2015, 1, 14),
  DateTime(2018, 12, 15),
  DateTime(2022, 11, 21),
]);

final btcCycleTops = List<DateTime>.unmodifiable([
  // DateTime(2013, 11, 30) // 첫 번째 고점은 제외
  DateTime(2017, 12, 17),
  DateTime(2021, 11, 10),
  DateTime(2025, 10, 6),
]);
