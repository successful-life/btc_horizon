import 'dart:convert';
import 'dart:io';

import 'package:btc_horizon/models/mvrv_history_cache.dart';

/// 한 저장 폴더에는 하나의 인스턴스를 사용합니다.
class MvrvHistoryCacheStore {
  MvrvHistoryCacheStore({required Directory directory}) : _directory = directory;

  static const fileName = 'mvrv_history_v1.json';

  // 비정상적으로 큰 파일을 읽거나 저장하지 않도록 제한합니다.
  static const maxFileBytes = 10 * 1024 * 1024;

  final Directory _directory;

  Future<void> _pending = Future<void>.value();

  File get _file => File('${_directory.path}${Platform.pathSeparator}$fileName');

  File get _backup => File('${_file.path}.bak');

  /// 읽기와 쓰기가 서로 겹치지 않도록 호출 순서대로 실행합니다.
  Future<T> _run<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());

    // 한 작업이 실패해도 다음 작업은 실행할 수 있어야 합니다.
    // 호출자는 result를 통해 원래 오류를 받습니다.
    _pending = result.then<void>((_) {}, onError: (Object error, StackTrace stackTrace) {});

    return result;
  }

  /// 기본 파일을 사용할 수 없으면 이전 정상 저장본을 읽습니다.
  Future<MvrvHistoryCache?> load() => _run(() async {
    return await _read(_file) ?? await _read(_backup);
  });

  Future<MvrvHistoryCache?> _read(File file) async {
    try {
      if (!await file.exists()) {
        return null;
      }

      if (await file.length() > maxFileBytes) {
        return null;
      }

      final decoded = jsonDecode(await file.readAsString());

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return MvrvHistoryCache.fromJson(decoded);
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// 저장 실패는 호출자에게 전달합니다.
  Future<void> save(MvrvHistoryCache cache) => _run(() async {
    final encoded = jsonEncode(cache.toJson());

    if (utf8.encode(encoded).length > maxFileBytes) {
      throw const FormatException('MVRV 캐시의 저장 크기 제한을 초과했습니다.');
    }

    await _directory.create(recursive: true);

    final file = _file;
    final temporary = File('${file.path}.tmp');

    try {
      // 기존 정상 파일 대신 임시 파일에 먼저 기록합니다.
      await temporary.writeAsString(encoded, flush: true);

      if (await file.exists()) {
        if (await _read(file) != null) {
          // 정상 파일만 백업합니다.
          // 손상된 파일로 기존 백업을 덮지 않습니다.
          if (await _backup.exists()) {
            await _backup.delete();
          }

          await file.rename(_backup.path);
        } else {
          await file.delete();
        }
      }

      // 기본 파일이 없는 경로로 이동합니다.
      // 실패하더라도 load()는 남아 있는 백업을 읽을 수 있습니다.
      await temporary.rename(file.path);
    } finally {
      try {
        if (await temporary.exists()) {
          await temporary.delete();
        }
      } on FileSystemException {
        // 임시 파일 정리 실패가 원래 저장 결과를 가리지 않게 합니다.
      }
    }
  });
}
