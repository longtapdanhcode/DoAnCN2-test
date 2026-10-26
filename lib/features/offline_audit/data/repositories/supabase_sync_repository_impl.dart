import 'package:flutter/foundation.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:field_inventory_edge_ai/core/database/local_db_init.dart';
import 'package:field_inventory_edge_ai/core/network/supabase_provider.dart';
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

  const SupabaseSyncRepositoryImpl(this._supabaseClient, this._isar);

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

        final cloudModel = CloudAuditRecordModel.fromAuditRecordModel(
          record,
          signatureUrl: uploadedUrl,
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
  return SupabaseSyncRepositoryImpl(supabaseClient, isar);
}
