enum BinanceSymbol {
  btcusdt('BTCUSDT'),
  ethusdt('ETHUSDT');

  const BinanceSymbol(this.value);
  final String value;

  String get restApi => value;
  String get webSocket => value.toLowerCase();
}
