import 'package:btc_horizon/providers/upbit_price_provider.dart';
import 'package:btc_horizon/providers/bithumb_price_provider.dart';
import 'package:btc_horizon/enums/binance_symbol.dart';
import 'package:btc_horizon/providers/binance_price_provider.dart';
import 'package:btc_horizon/providers/analysis_date_provider.dart';
import 'package:btc_horizon/providers/refresh_scheduler_provider.dart';
import 'package:btc_horizon/services/refresh_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ProviderScope 바로 아래, MaterialApp 위에 한 번만 배치함
class AppRefreshScope extends ConsumerStatefulWidget {
  const AppRefreshScope({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppRefreshScope> createState() => _AppRefreshScopeState();
}

class _AppRefreshScopeState extends ConsumerState<AppRefreshScope>
    with WidgetsBindingObserver {
  late RefreshScheduler _scheduler;

  @override
  void initState() {
    super.initState();
    _scheduler = ref.read(refreshSchedulerProvider);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _scheduler.setActive(
      lifecycle == null || lifecycle == AppLifecycleState.resumed,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(analysisDateProvider.notifier).refresh();
      _scheduler.setActive(true);
      for (final symbol in BinanceSymbol.values) {
        final provider = binanceSocketServiceProvider(symbol);
        if (ref.exists(provider)) {
          ref.read(provider).checkConnection();
        }
      }
      // 현재 앱에서 사용하는 KRW-USDT의 기존 연결만 확인한다.
      const market = 'KRW-USDT';
      final upbitService = upbitSocketServiceProvider(market);
      if (ref.exists(upbitService)) {
        ref.read(upbitService).checkConnection();
      }
      final bithumbService = bithumbSocketServiceProvider(market);
      if (ref.exists(bithumbService)) {
        ref.read(bithumbService).checkConnection();
      }
    } else {
      _scheduler.setActive(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduler.setActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
