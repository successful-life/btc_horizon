import 'package:btc_horizon/data/refresh_policy.dart';
import 'package:btc_horizon/models/fear_greed_model.dart';
import 'package:btc_horizon/providers/fear_greed_provider.dart';
import 'package:btc_horizon/utils/fear_greed_history.dart';
import 'package:btc_horizon/utils/fetch_with_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 상세 화면 전용. 홈 점수와 기존 최신 점수 provider는 변경하지 않습니다.
final fearGreedHistoryProvider =
    FutureProvider.autoDispose<List<FearGreedModel>>((ref) {
      final service = ref.watch(fearGreedServiceProvider);
      return fetchWithRefresh(
        ref: ref,
        fetch: () async {
          final values = normalizeFearGreedHistory(
            await service
                .fetchFearGreed(limit: 0)
                .timeout(const Duration(seconds: 20)),
          );
          if (values.isEmpty) throw StateError('Fear & Greed 과거 기록이 비어 있습니다.');
          return values;
        },
        refreshAfter: kMetadataFallbackInterval,
      );
    }, retry: disableAutomaticRetry);
