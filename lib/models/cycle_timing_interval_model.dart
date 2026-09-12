class CycleTimingIntervalModel {
  final DateTime startDate;
  final DateTime endDate;

  const CycleTimingIntervalModel({required this.startDate, required this.endDate});

  int get durationDays => endDate.difference(startDate).inDays;
}
