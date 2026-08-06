enum BinanceKlineInterval {
  oneMinute('1m'),
  fiveMinutes('5m'),
  fifteenMinutes('15m'),
  oneHour('1h'),
  fourHours('4h'),
  oneDay('1d'),
  oneWeek('1w'),
  oneMonth('1M');

  const BinanceKlineInterval(this.value);

  final String value;
}
