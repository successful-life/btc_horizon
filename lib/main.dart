import 'package:btc_horizon/screens/home_screen.dart';
import 'package:btc_horizon/services/upbit_socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  print('--------start');

  final service = UpbitSocketService(market: "KRW-USDT");
  service.getPriceStream().listen((price) {
    print(price);
  });
  print('-------end');

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}
