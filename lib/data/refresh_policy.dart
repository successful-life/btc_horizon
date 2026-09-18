// 애플리케이션의 초기 설정값이며,
// 상위 API의 Rate Limit을 보장하는 값은 아님
const kFundingRefreshInterval = Duration(minutes: 5);
const kKlineRefreshInterval = Duration(minutes: 15);
const kMvrvRefreshInterval = Duration(days: 1);
const kMvrvRetryInterval = Duration(hours: 6);
const kMetadataFallbackInterval = Duration(hours: 6);

DateTime nextUtcDailyRefresh(DateTime now) {
  final utc = now.toUtc();
  final today = DateTime.utc(utc.year, utc.month, utc.day, 0, 5);
  return now.isBefore(today) ? today : DateTime.utc(utc.year, utc.month, utc.day + 1, 0, 5);
}
