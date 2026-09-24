import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

/// Upbit와 Bithumb의 DEFAULT ticker 구독 및 연결 복구를 담당한다.
class TickerSocketService {
  TickerSocketService({
    required this.exchangeName,
    required this.endpoint,
    required String market,
    WebSocketChannel Function(Uri)? connect,
    DateTime Function()? now,
    this.onLog,
    this.connectTimeout = const Duration(seconds: 15),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.messageTimeout = const Duration(seconds: 45),
    this.priceResponseTimeout = const Duration(seconds: 30),
    this.snapshotRefreshInterval = const Duration(minutes: 5),
  }) : market = market.toUpperCase(),
       _connect = connect ?? WebSocketChannel.connect,
       _now = now ?? DateTime.now;

  final String exchangeName;
  final Uri endpoint;
  final String market;
  final WebSocketChannel Function(Uri) _connect;
  final DateTime Function() _now;
  final void Function(String)? onLog;
  final Duration connectTimeout;
  final Duration heartbeatInterval;
  final Duration messageTimeout;
  final Duration priceResponseTimeout;
  final Duration snapshotRefreshInterval;

  late final _prices = StreamController<double>.broadcast(onListen: _start);
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  Timer? _heartbeatTimer;
  Timer? _messageTimer;
  Timer? _priceResponseTimer;
  Timer? _snapshotTimer;
  DateTime? _lastReceivedAt;
  DateTime? _lastMessageAt;
  bool _started = false;
  bool _disposed = false;
  bool _connecting = false;
  bool _receivedOnConnection = false;
  bool _waitingForPrice = false;
  int _generation = 0;
  int _failures = 0;

  /// 마지막 정상 가격 메시지를 받은 시각이며, 마지막 체결 시각과는 다르다.
  DateTime? get lastReceivedAt => _lastReceivedAt;
  DateTime? get lastMessageAt => _lastMessageAt;

  Stream<double> getPriceStream() => _prices.stream;

  void _log(String message) {
    onLog?.call('[$exchangeName $market] $message');
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _start() {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    unawaited(_open());
  }

  Future<void> _open() async {
    if (_disposed || _connecting || _channel != null) {
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _connecting = true;
    _receivedOnConnection = false;
    _lastMessageAt = null;
    final generation = ++_generation;
    _log('연결 시도');

    try {
      final channel = _connect(endpoint);
      _channel = channel;
      // 연결 실패가 ready와 스트림 양쪽으로 전달될 수 있어 먼저 구독한다.
      _subscription = channel.stream.listen(
        (message) => _onMessage(generation, message),
        onError: (Object error, StackTrace stack) => _failed(generation, error, stack),
        onDone: () => _failed(generation, StateError('시세 연결이 종료되었습니다.')),
      );
      await channel.ready.timeout(connectTimeout);
      if (!_isCurrent(generation)) {
        return;
      }
      _connecting = false;
      _armMessageTimeout(generation);
      // 새 연결에는 기존 구독이 남아 있지 않으므로 매번 다시 요청한다.
      _requestTicker(generation);
      if (!_isCurrent(generation)) {
        return;
      }
      _sendPing(generation);
      if (!_isCurrent(generation)) {
        return;
      }
      _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) => _sendPing(generation));
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _requestTicker(int generation) {
    if (!_isCurrent(generation) || _channel == null || _waitingForPrice) {
      return;
    }
    try {
      _waitingForPrice = true;
      _priceResponseTimer?.cancel();
      _priceResponseTimer = Timer(priceResponseTimeout, () {
        _failed(generation, TimeoutException('구독 요청 후 가격을 받지 못했습니다.', priceResponseTimeout));
      });
      // 두 옵션의 기본값을 사용해 스냅샷과 실시간 시세를 함께 구독한다.
      _channel!.sink.add(
        jsonEncode([
          {'ticket': 'btc_horizon_${market}_${_now().microsecondsSinceEpoch}_$generation'},
          {
            'type': 'ticker',
            'codes': [market],
          },
          {'format': 'DEFAULT'},
        ]),
      );
      _log('시세 구독 요청');
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _sendPing(int generation) {
    if (!_isCurrent(generation) || _channel == null) {
      return;
    }
    try {
      // 두 거래소에서 지원하는 문자열 PING 방식으로 연결 상태를 확인한다.
      _channel!.sink.add('PING');
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _onMessage(int generation, dynamic message) {
    if (!_isCurrent(generation)) {
      return;
    }
    try {
      final text = message is String ? message : utf8.decode(message as List<int>);
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (json.containsKey('error')) {
        throw StateError('$exchangeName 구독 오류: ${json['error']}');
      }
      if (json['status'] == 'UP') {
        // 연결 확인 응답을 가격으로 변환하거나 가격 수신 시각에 반영하지 않는다.
        _lastMessageAt = _now();
        _armMessageTimeout(generation);
        return;
      }
      if (json['type'] != 'ticker' || json['code'] != market) {
        return;
      }
      final value = json['trade_price'];
      final price = value is num ? value.toDouble() : double.tryParse(value.toString());
      if (price == null || !price.isFinite || price <= 0) {
        throw const FormatException('유효한 현재가가 없는 메시지입니다.');
      }
      _lastReceivedAt = _now();
      _lastMessageAt = _lastReceivedAt;
      _waitingForPrice = false;
      _priceResponseTimer?.cancel();
      _priceResponseTimer = null;
      _failures = 0;
      if (!_receivedOnConnection) {
        _log('가격 수신 시작: $_lastReceivedAt');
      }
      _receivedOnConnection = true;
      _armMessageTimeout(generation);
      _snapshotTimer?.cancel();
      // 체결이 뜸하면 연결을 끊는 대신 현재가 스냅샷을 다시 요청한다.
      _snapshotTimer = Timer(snapshotRefreshInterval, () => _requestTicker(generation));
      _prices.add(price);
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _armMessageTimeout(int generation) {
    _messageTimer?.cancel();
    _messageTimer = Timer(messageTimeout, () {
      _failed(generation, TimeoutException('서버 응답이 중단되었습니다.', messageTimeout));
    });
  }

  void _failed(int generation, Object error, [StackTrace? stack]) {
    if (!_isCurrent(generation)) {
      return;
    }
    ++_generation; // 이전 연결에서 늦게 전달되는 오류와 데이터는 무시한다.
    _releaseConnection();
    _prices.addError(error, stack ?? StackTrace.current);
    final seconds = math.min(30, 1 << math.min(_failures, 5));
    _failures++;
    _log('수신 중단, $seconds초 후 재연결');
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), () => unawaited(_open()));
  }

  /// 앱 복귀 시 기존 연결을 확인하고, 진행 중인 연결 시도는 중복하지 않는다.
  void checkConnection() {
    if (_disposed || !_started || _connecting) {
      return;
    }
    if (_channel != null) {
      final last = _lastMessageAt;
      if (last == null) {
        return; // 새 연결의 첫 응답은 기존 대기 타이머가 확인한다.
      }
      final age = _now().difference(last);
      if (!age.isNegative && age < messageTimeout) {
        final priceDate = _lastReceivedAt;
        if (priceDate != null && _now().difference(priceDate) >= snapshotRefreshInterval) {
          _requestTicker(_generation);
        }
        return;
      }
      _failed(_generation, StateError('앱 복귀 후 연결을 다시 확인합니다.'));
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_open());
  }

  void _releaseConnection() {
    _heartbeatTimer?.cancel();
    _messageTimer?.cancel();
    _priceResponseTimer?.cancel();
    _snapshotTimer?.cancel();
    _heartbeatTimer = null;
    _messageTimer = null;
    _priceResponseTimer = null;
    _snapshotTimer = null;
    _connecting = false;
    _receivedOnConnection = false;
    _waitingForPrice = false;
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
      // 서버와의 연결이 이미 끊어진 경우에도 나머지 정리는 계속한다.
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    ++_generation;
    _retryTimer?.cancel();
    _releaseConnection();
    unawaited(_prices.close());
  }
}
