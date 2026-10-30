import 'dart:io';

import 'package:btc_horizon/services/mvrv_history_cache_store.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final mvrvHistoryCacheStoreProvider = FutureProvider<MvrvHistoryCacheStore?>((ref) async {
  try {
    final db = FirebaseFirestore.instance;

    // 실제 서버와 에뮬레이터, 서로 다른 프로젝트의 자료를 분리합니다.
    final projectId = db.app.options.projectId;
    final databaseId = db.databaseId;
    final host = db.settings.host ?? 'firestore.googleapis.com';

    final scope = Uri.encodeComponent('$projectId|$databaseId|$host');

    final supportDirectory = await getApplicationSupportDirectory();

    final directory = Directory(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}mvrv_history'
      '${Platform.pathSeparator}$scope',
    );

    if (kDebugMode) {
      debugPrint('MVRV 캐시 폴더: ${directory.path}');
    }

    return MvrvHistoryCacheStore(directory: directory);
  } on Exception catch (error) {
    if (kDebugMode) {
      debugPrint('MVRV 캐시 저장 공간 준비 실패: $error');
    }

    // 저장 공간을 준비하지 못해도 서버 차트 조회는 계속할 수 있습니다.
    return null;
  }
}, retry: disableAutomaticRetry);
