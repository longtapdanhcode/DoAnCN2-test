import 'package:flutter/foundation.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:field_inventory_edge_ai/core/database/local_db_init.dart';
import 'package:field_inventory_edge_ai/core/network/supabase_provider.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/evidence_photo_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/cloud_audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/sync_repository.dart';

part 'supabase_sync_repository_impl.g.dart';

/// Implementation của [SyncRepository] sử dụng Supabase làm Cloud Storage & Database.
///
/// Quản lý việc đẩy dữ liệu ngoại tuyến (Offline-First) từ Isar lên Supabase.
class SupabaseSyncRepositoryImpl implements SyncRepository {
  final SupabaseClient _supabaseClient;
  final Isar _isar;
  final EvidencePhotoStore _photos;

  const SupabaseSyncRepositoryImpl(
    this._supabaseClient,
    this._isar,
    this._photos,
  );

  static const _evidenceBucket = 'evidence';

  @override
  Future<String?> uploadSignature(List<int> bytes) async {
    if (bytes.isEmpty) return null;

    try {
      final fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
      await _supabaseClient.storage
          .from('signatures')
          .uploadBinary(
            fileName,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
      return _supabaseClient.storage.from('signatures').getPublicUrl(fileName);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseSync] Cảnh báo lỗi upload signature: $e\n$stackTrace',
        );
      }
      return null;
    }
  }

  @override
  Future<String> uploadEvidencePhoto(List<int> bytes) async {
    final fileName =
        'ev_${DateTime.now().millisecondsSinceEpoch}_${bytes.length}.jpg';
    await _supabaseClient.storage
        .from(_evidenceBucket)
        .uploadBinary(
          fileName,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _supabaseClient.storage.from(_evidenceBucket).getPublicUrl(fileName);
  }

  @override
  Future<void> syncPendingRecords(List<AuditRecordModel> records) async {
    final pendingRecords = records
        .where((record) => !record.isSynced && !record.isDraft)
        .toList();
    if (pendingRecords.isEmpty) return;

    for (final record in pendingRecords) {
      try {
        String? uploadedUrl;
        if (record.signatureBytes != null &&
            record.signatureBytes!.isNotEmpty) {
          uploadedUrl = await uploadSignature(record.signatureBytes!);
        }

        // Ảnh minh chứng: mọi ảnh phải lên được thì phiếu mới được coi là đã
        // đồng bộ (lỗi sẽ ném ra và phiếu ở lại hàng chờ).
        final photoUrls = <String>[];
        for (final name in record.photoFiles ?? const <String>[]) {
          final bytes = await _photos.read(name);
          if (bytes == null) continue; // tệp đã mất trên máy
          photoUrls.add(await uploadEvidencePhoto(bytes));
        }

        final cloudModel = CloudAuditRecordModel.fromAuditRecordModel(
          record,
          signatureUrl: uploadedUrl,
          photoUrls: photoUrls,
        );

        await _supabaseClient.from('audit_records').upsert(cloudModel.toJson());

        record.isSynced = true;
        await _isar.writeAsync((isar) {
          isar.auditRecordModels.put(record);
        });
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[SupabaseSync] Cảnh báo lỗi đồng bộ record #${record.id}: $e\n$stackTrace',
          );
        }
        rethrow;
      }
    }
  }
}

/// Riverpod provider cung cấp instance [SyncRepository].
@riverpod
SyncRepository syncRepository(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isar = ref.watch(isarInstanceProvider);
  final photos = ref.watch(evidencePhotoStoreProvider);
  return SupabaseSyncRepositoryImpl(supabaseClient, isar, photos);
}
