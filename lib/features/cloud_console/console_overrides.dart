import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:field_inventory_edge_ai/core/network/supabase_provider.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/repositories/asset_catalog_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/evidence_photo_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';

import 'data/cloud_console_data.dart';

/// Phiếu kiểm kê trên máy chủ cho bản web; tải lại mỗi phút.
final cloudAuditSourceProvider = Provider<CloudAuditSource>(
  (ref) => SupabaseCloudAuditSource(ref.watch(supabaseClientProvider)),
);

Stream<List<AuditRecordModel>> _cloudRecords(Ref ref) async* {
  final source = ref.watch(cloudAuditSourceProvider);
  while (true) {
    yield cloudRowsToRecords(await source.fetchAll());
    await Future<void>.delayed(const Duration(minutes: 1));
  }
}

/// Bản web (Card 28): thay nguồn dữ liệu trên máy (Isar, tệp) bằng Supabase.
/// Các màn Tổng quan, Tài sản, Báo cáo, Địa điểm, Cài đặt dùng lại nguyên.
List<Override> consoleOverrides() => [
  auditRecordsProvider.overrideWith(_cloudRecords),
  evidencePhotoStoreProvider.overrideWithValue(UrlEvidencePhotoStore()),
  assetCatalogRepositoryProvider.overrideWith(
    (ref) => CloudAssetCatalogRepository(
      SupabaseAssetRemoteDataSource(ref.watch(supabaseClientProvider)),
    ),
  ),
];
