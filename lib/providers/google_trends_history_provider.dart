import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:btc_horizon/models/google_trends_history_model.dart';

const googleTrendsDocumentPath = 'search_interest_latest/kr_bitcoin_monthly';

final googleTrendsHistoryByRegionProvider = StreamProvider.autoDispose
    .family<GoogleTrendsHistoryModel, GoogleTrendsRegion>((ref, region) {
      return FirebaseFirestore.instance
          .doc(region.documentPath)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            final data = snapshot.data();
            if (data == null) throw StateError('검색 관심도 데이터가 아직 등록되지 않았습니다.');
            return GoogleTrendsHistoryModel.fromMap(
              data,
              expectedRegion: region,
              fromCache: snapshot.metadata.isFromCache,
            );
          });
    }, retry: (_, _) => null);

// 기존 한국 자료 구독 코드와의 호환성을 유지합니다.
final googleTrendsHistoryProvider = googleTrendsHistoryByRegionProvider(GoogleTrendsRegion.korea);
