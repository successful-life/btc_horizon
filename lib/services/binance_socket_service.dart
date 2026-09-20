import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

class BinanceSocketService {
  BinanceSocketService({
    required this.symbol,
    WebSocketChannel Function(Uri)? connect,
    DateTime Function()? now,
    this.onLog,
    this.connectTimeout = const Duration(seconds: 15),
    this.priceTimeout = const Duration(seconds: 30),
  }) : _connect = connect ?? WebSocketChannel.connect,
       _now = now ?? DateTime.now;

  final String symbol;
  final WebSocketChannel Function(Uri) _connect;
  final DateTime Function() _now;
  final void Function(String)? onLog;
  final Duration connectTimeout;
  final Duration priceTimeout;

  late final _prices = StreamController<double>.broadcast(onListen: _start);
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  Timer? _priceTimer;
  DateTime? _lastReceivedAt;
  int _generation = 0;
  int _failures = 0;
  bool _started = false;
  bool _disposed = false;
  bool _connecting = false;
  bool _receivedOnConnection = false;

  DateTime? get lastReceivedAt => _lastReceivedAt;

  Stream<double> getPriceStream() => _prices.stream;

  void _start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_open());
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> _open() async {
    if (_disposed || _connecting || _channel != null) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _connecting = true;
    _receivedOnConnection = false;
    final generation = ++_generation;
    onLog?.call('[Binance $symbol] 연결 시도');

    try {
      final channel = _connect(Uri.parse('wss://stream.binance.com:9443/ws/$symbol@miniTicker'));
      _channel = channel;
      // 연결 실패가 ready와 스트림 양쪽으로 전달될 수 있으므로,
      // ready를 기다리기 전에 스트림 구독을 등록한다.
      _subscription = channel.stream.listen(
        (message) => _onMessage(generation, message),
        onError: (Object error, StackTrace stack) => _failed(generation, error, stack),
        onDone: () => _failed(generation, StateError('가격 연결이 종료되었습니다.')),
      );
      await channel.ready.timeout(connectTimeout);
      if (!_isCurrent(generation)) return;
      _connecting = false;
      if (!_receivedOnConnection) _armPriceTimeout(generation);
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _onMessage(int generation, dynamic message) {
    if (!_isCurrent(generation)) return;
    try {
      final text = message is String ? message : utf8.decode(message as List<int>);
      final json = jsonDecode(text) as Map<String, dynamic>;
      final value = json['c'];
      final price = value is num ? value.toDouble() : double.tryParse(value.toString());
      if (price == null || !price.isFinite || price <= 0) {
        throw const FormatException('유효한 가격이 없는 메시지입니다.');
      }

      _lastReceivedAt = _now();
      _failures = 0; // 연결 성공만으로는 복구로 판단하지 않고, 정상 가격 수신을 기준으로 판단한다.
      if (!_receivedOnConnection) {
        onLog?.call('[Binance $symbol] 가격 수신 시작: $_lastReceivedAt');
      }
      _receivedOnConnection = true;
      _armPriceTimeout(generation);
      _prices.add(price); // 가격이 이전과 같아도 정상적으로 수신한 메시지로 처리한다.
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _armPriceTimeout(int generation) {
    _priceTimer?.cancel();
    _priceTimer = Timer(priceTimeout, () {
      _failed(generation, TimeoutException('가격 수신이 지연되고 있습니다.', priceTimeout));
    });
  }

  void _failed(int generation, Object error, [StackTrace? stack]) {
    if (!_isCurrent(generation)) return;
    ++_generation; // 이전 연결에서 늦게 도착한 오류와 가격 데이터는 무시한다.
    _releaseConnection();
    _prices.addError(error, stack ?? StackTrace.current);

    final seconds = math.min(30, 1 << math.min(_failures, 5));
    _failures++;
    onLog?.call('[Binance $symbol] 수신 중단, $seconds초 후 재연결');
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), () => unawaited(_open()));
  }

  /// 앱이 다시 활성화될 때 연결 상태를 확인한다.
  /// 이미 연결을 시도 중이면 추가 연결을 만들지 않는다.
  void checkConnection() {
    if (_disposed || !_started || _connecting) return;
    final last = _lastReceivedAt;
    if (_channel != null && last != null && _receivedOnConnection) {
      final age = _now().difference(last);
      if (!age.isNegative && age < priceTimeout) return;
    }
    // 새 연결이 첫 가격을 수신할 수 있도록 설정된 대기 시간을 보장한다.
    if (_channel != null && !_receivedOnConnection) return;
    if (_channel != null) {
      _failed(_generation, StateError('앱 복귀 후 가격 연결을 다시 확인합니다.'));
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_open());
  }

  void _releaseConnection() {
    _priceTimer?.cancel();
    _priceTimer = null;
    _connecting = false;
    _receivedOnConnection = false;
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    if (subscription != null) {
      unawaited(_ignoreCleanupError(subscription.cancel));
    }

    if (channel != null) {
      unawaited(_ignoreCleanupError(() => channel.sink.close()));
    }
  }

  Future<void> _ignoreCleanupError(Future<dynamic> Function() cleanup) async {
    try {
      await cleanup();
    } catch (_) {
      // 상대 서버와의 연결이 이미 끊어졌거나 종료된 상태일 수 있다.
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _retryTimer?.cancel();
    _releaseConnection();
    unawaited(_prices.close());
  }
}
