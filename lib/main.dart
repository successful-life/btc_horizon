import 'package:btc_horizon/screens/home_screen.dart';
import 'package:btc_horizon/widgets/app_refresh_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

  debugPrint('Firestore 에뮬레이터 사용: $useFirebaseEmulator');

  if (useFirebaseEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator(
      '10.0.2.2', // Android Emulator에서 PC에 접근하는 주소
      8080,
    );
  }

  await dotenv.load();

  runApp(const ProviderScope(child: AppRefreshScope(child: MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}
