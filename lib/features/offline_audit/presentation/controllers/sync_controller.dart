import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/isar_audit_repository_impl.dart';
import '../../data/repositories/supabase_sync_repository_impl.dart';

part 'sync_controller.g.dart';

/// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.
@riverpod
class SyncController extends _$SyncController {
  @override
  FutureOr<void> build() {
    // Trạng thái ban đầu: idle
  }

  /// Đồng bộ tất cả bản ghi chưa được đồng bộ (`isSynced == false`) lên Supabase.
  ///
  /// Trả về số lượng bản ghi đã đồng bộ thành công.
  Future<int> syncAll() async {
    state = const AsyncLoading();

    try {
      final auditRepo = ref.read(isarAuditRepositoryProvider);
      final allRecords = await auditRepo.getAllRecords();
      final pendingRecords = allRecords.where((r) => !r.isSynced).toList();

      if (pendingRecords.isEmpty) {
        state = const AsyncData(null);
        return 0;
      }

      final syncRepo = ref.read(syncRepositoryProvider);
      await syncRepo.syncPendingRecords(pendingRecords);

      final syncedCount = pendingRecords.where((r) => r.isSynced).length;
      state = const AsyncData(null);
      return syncedCount;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[SyncController] Lỗi khi đồng bộ lên Supabase: $e\n$stackTrace',
        );
      }
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }
}
