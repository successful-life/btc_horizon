import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:btc_horizon/models/binance_kline_model.dart';
import 'package:btc_horizon/models/trend_candle_model.dart';
import 'package:btc_horizon/models/weekly_trend_market_model.dart';
import 'package:btc_horizon/utils/trend_candle_calculator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WeeklyKlineEvent {
  final TrendCandle candle;
  final DateTime time;
  const WeeklyKlineEvent(this.candle, this.time);
  factory WeeklyKlineEvent.fromJson(Map<String, dynamic> json) {
    final k = Map<String, dynamic>.from(json['k'] as Map);
    if (json['e'] != 'kline' ||
        json['s'] != 'BTCUSDT' ||
        k['s'] != 'BTCUSDT' ||
        k['i'] != '1w' ||
        k['x'] is! bool) {
      throw const FormatException('BTCUSDT 주봉 메시지가 아닙니다.');
    }
    DateTime date(dynamic v) =>
        DateTime.fromMillisecondsSinceEpoch(v as int, isUtc: true);
    double number(String key) => double.parse(k[key].toString());
    final open = date(k['t']);
    final candle = TrendCandle(
      openTime: open,
      endExclusive: trendWeekEnd(open),
      open: number('o'),
      high: number('h'),
      low: number('l'),
      close: number('c'),
      volume: number('v'),
      isClosed: k['x'] as bool,
    );
    validateTrendCandle(candle);
    if (date(k['T']).add(const Duration(milliseconds: 1)) !=
        candle.endExclusive) {
      throw const FormatException('주봉 종료 경계가 올바르지 않습니다.');
    }
    final eventTime = date(json['E']);
    if (eventTime.isBefore(open)) {
      throw const FormatException('주봉 이벤트 시각이 올바르지 않습니다.');
    }
    if (candle.isClosed &&
        eventTime.isBefore(
          candle.endExclusive.subtract(const Duration(milliseconds: 1)),
        )) {
      throw const FormatException('주봉 마감 이전에 확정된 메시지입니다.');
    }
    return WeeklyKlineEvent(candle, eventTime);
  }
}

/// REST로 연속된 기록을 준비한 뒤, 소켓의 완전한 OHLC로 해당 주를 교체합니다.
/// 재접속 시 REST부터 다시 동기화하여 누락된 주와 마감 이벤트를 복구합니다.
class BinanceWeeklyTrendService {
  BinanceWeeklyTrendService({
    required this.fetchHistory,
    WebSocketChannel Function(Uri)? connect,
    DateTime Function()? now,
    this.requestTimeout = const Duration(seconds: 15),
    this.staleAfter = const Duration(seconds: 30),
    this.retryBase = const Duration(seconds: 1),
  }) : _connect = connect ?? WebSocketChannel.connect,
       _now = now ?? DateTime.now;
  final Future<List<BinanceKlineModel>> Function() fetchHistory;
  final WebSocketChannel Function(Uri) _connect;
  final DateTime Function() _now;
  final Duration requestTimeout, staleAfter, retryBase;
  late final _controller = StreamController<WeeklyMarketSnapshot>.broadcast(
    onListen: _start,
  );
  Stream<WeeklyMarketSnapshot> get stream => _controller.stream;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry, _watchdog;
  List<TrendCandle> _candles = [];
  DateTime? _receivedAt, _eventTime;
  int _generation = 0, _failures = 0;
  bool _started = false, _disposed = false, _opening = false;
  bool _receivedOnConnection = false;

  bool _current(int generation) => !_disposed && generation == _generation;
  void _start() {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    unawaited(_open());
  }

  void _emit(TrendConnection connection) {
    if (_disposed || _candles.isEmpty) {
      return;
    }
    _controller.add(
      WeeklyMarketSnapshot(
        candles: _candles,
        connection: connection,
        receivedAt: _receivedAt!,
        eventTime: _eventTime,
      ),
    );
  }

  Future<void> _open() async {
    if (_disposed || _opening || _channel != null) {
      return;
    }
    _retry?.cancel();
    _opening = true;
    _receivedOnConnection = false;
    final generation = ++_generation;
    _emit(TrendConnection.reconnecting);
    try {
      final history = await fetchHistory().timeout(requestTimeout);
      if (!_current(generation)) {
        return;
      }
      _candles = weeklyCandlesFromRest(history, _now());
      _eventTime = null;
      _receivedAt = _now().toUtc();
      _emit(TrendConnection.connecting);
      final channel = _connect(
        Uri.parse('wss://stream.binance.com:9443/ws/btcusdt@kline_1w'),
      );
      _channel = channel;
      _subscription = channel.stream.listen(
        (message) => _onMessage(generation, message),
        onError:
            (Object error, StackTrace stack) =>
                _failed(generation, error, stack),
        onDone: () => _failed(generation, StateError('주봉 연결이 종료되었습니다.')),
      );
      await channel.ready.timeout(requestTimeout);
      if (!_current(generation)) {
        return;
      }
      _opening = false;
      if (!_receivedOnConnection) {
        _armWatchdog(generation);
      }
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _onMessage(int generation, dynamic message) {
    if (!_current(generation)) {
      return;
    }
    try {
      final decoded = jsonDecode(
        message is String ? message : utf8.decode(message as List<int>),
      );
      final event = WeeklyKlineEvent.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
      final c = event.candle;
      final last = _candles.last;
      final age = _now().toUtc().difference(event.time);
      if (age > staleAfter || age < const Duration(minutes: -1)) {
        throw StateError('주봉 이벤트 수신 시각이 오래되었거나 기기 시각과 맞지 않습니다.');
      }
      if (c.openTime.isBefore(last.openTime)) {
        return;
      }
      if (_eventTime != null && !event.time.isAfter(_eventTime!)) {
        return;
      }
      if (c.openTime == last.openTime) {
        // 마감된 봉을 늦게 도착한 미확정 메시지로 되돌리지 않습니다.
        if (last.isClosed && !c.isClosed) {
          return;
        }
        _candles = [..._candles.take(_candles.length - 1), c];
      } else {
        if (c.openTime != last.endExclusive || !last.isClosed) {
          throw StateError('주봉 경계의 누락 데이터를 다시 동기화합니다.');
        }
        _candles = [..._candles, c];
        if (_candles.length > 1000) {
          _candles = _candles.sublist(_candles.length - 1000);
        }
      }
      _eventTime = event.time;
      _receivedAt = _now().toUtc();
      _receivedOnConnection = true;
      _failures = 0;
      _armWatchdog(generation);
      _emit(TrendConnection.live);
    } catch (error, stack) {
      _failed(generation, error, stack);
    }
  }

  void _armWatchdog(int generation) {
    _watchdog?.cancel();
    _watchdog = Timer(
      staleAfter,
      () => _failed(
        generation,
        TimeoutException('주봉 수신이 지연되고 있습니다.', staleAfter),
      ),
    );
  }

  void _failed(int generation, Object error, [StackTrace? stack]) {
    if (!_current(generation)) {
      return;
    }
    ++_generation;
    _release();
    if (_candles.isEmpty) {
      _controller.addError(error, stack ?? StackTrace.current);
    } else {
      _emit(TrendConnection.reconnecting);
    }
    final multiplier = 1 << math.min(_failures++, 5);
    final delay = Duration(
      milliseconds: math.min(30000, retryBase.inMilliseconds * multiplier),
    );
    _retry?.cancel();
    _retry = Timer(delay, () => unawaited(_open()));
  }

  /// 새로고침 및 앱 복귀 시 같은 스트림을 유지하며 기록부터 다시 맞춥니다.
  void checkConnection() {
    if (_disposed || !_started) {
      return;
    }
    ++_generation;
    _retry?.cancel();
    _release();
    _emit(TrendConnection.reconnecting);
    unawaited(_open());
  }

  void _release() {
    _watchdog?.cancel();
    _opening = false;
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    if (subscription != null) {
      unawaited(_ignore(subscription.cancel));
    }
    if (channel != null) {
      unawaited(_ignore(() => channel.sink.close()));
    }
  }

  Future<void> _ignore(Future<dynamic> Function() cleanup) async {
    try {
      await cleanup();
    } catch (_) {
      /* 이미 종료된 연결 */
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    ++_generation;
    _retry?.cancel();
    _release();
    unawaited(_controller.close());
  }
}
