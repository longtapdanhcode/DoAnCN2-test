import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';

import '../../data/evidence_photo_store.dart';
import '../../data/models/audit_record_model.dart';
import '../../data/repositories/isar_audit_repository_impl.dart';
import '../../domain/entities/audit_condition.dart';

part 'audit_form_controller.g.dart';

/// Trạng thái của biểu mẫu kiểm kê động.
enum AuditFormStatus { initial, saving, success, error }

/// State object chứa thông tin trạng thái form và thông báo lỗi (nếu có).
class AuditFormState {
  final AuditFormStatus status;
  final String? errorMessage;

  const AuditFormState({
    this.status = AuditFormStatus.initial,
    this.errorMessage,
  });

  bool get isSaving => status == AuditFormStatus.saving;
  bool get isSuccess => status == AuditFormStatus.success;
  bool get hasError => status == AuditFormStatus.error;

  AuditFormState copyWith({AuditFormStatus? status, String? errorMessage}) {
    return AuditFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Controller quản lý luồng nhập và lưu bản ghi kiểm kê hiện trường.
///
/// Sử dụng Riverpod [AutoDisposeNotifier] để tự động giải phóng tài nguyên
/// khi thoát khỏi màn hình kiểm kê.
@riverpod
class AuditFormController extends _$AuditFormController {
  @override
  AuditFormState build() {
    return const AuditFormState();
  }

  /// Gửi dữ liệu form và lưu vào Local Database (Isar).
  ///
  /// Trả về `true` nếu lưu thành công, `false` nếu xảy ra lỗi.
  Future<bool> submitForm({
    required String scanCode,
    String? aiLabel,
    String? assetName,
    required int quantity,
    String? area,
    String? location,
    String? condition,
    String? notes,
    List<int>? signatureBytes,
    String? signerName,
    String? signerRole,

    /// Khi hoàn tất một bản nháp: ghi đè chính phiếu đó thay vì tạo phiếu mới.
    int? draftId,
    List<String>? photoFiles,
  }) async {
    state = state.copyWith(status: AuditFormStatus.saving, errorMessage: null);

    try {
      final repository = ref.read(isarAuditRepositoryProvider);

      final record = AuditRecordModel(draftId ?? 0)
        ..scanCode = scanCode.trim()
        ..aiDetectedLabel = (aiLabel != null && aiLabel.trim().isNotEmpty)
            ? aiLabel.trim()
            : null
        ..assetName = _clean(assetName)
        ..quantity = quantity
        ..area = _clean(area)
        ..location = _clean(location)
        ..condition = _clean(condition)
        ..notes = _clean(notes)
        ..signatureBytes = signatureBytes
        ..signerName = _clean(signerName)
        ..signerRole = _clean(signerRole)
        ..photoFiles = (photoFiles == null || photoFiles.isEmpty)
            ? null
            : List.of(photoFiles)
        ..timestamp = DateTime.now()
        ..isSynced = false;

      await repository.saveRecord(record);
      // Bản nháp chưa tính là đã kiểm kê: chỉ phiếu đã ký mới cập nhật tài sản.
      if (!record.isDraft) await _markAssetAudited(record);

      state = state.copyWith(status: AuditFormStatus.success);
      return true;
    } catch (e, stackTrace) {
      debugPrint(
        '[AuditFormController] Lỗi khi lưu bản ghi kiểm kê: $e\n$stackTrace',
      );
      state = state.copyWith(
        status: AuditFormStatus.error,
        errorMessage: 'Lưu thất bại: $e',
      );
      return false;
    }
  }

  /// Ghi lần kiểm kê và tình trạng mới vào tài sản cùng mã trong danh mục.
  ///
  /// Tài sản chưa có trong danh mục thì bỏ qua. Lỗi ở bước này không làm hỏng
  /// việc lưu phiếu (phiếu đã nằm trên máy).
  Future<void> _markAssetAudited(AuditRecordModel record) async {
    final code = record.scanCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) return;
    try {
      final catalog = ref.read(assetCatalogRepositoryProvider);
      final asset = await catalog.findByCode(code);
      if (asset == null) return;
      asset.lastAuditAt = record.timestamp;
      final condition = AuditCondition.fromCode(record.condition);
      if (condition != null) asset.status = condition.code;
      await catalog.save(asset);
    } catch (e) {
      debugPrint('[AuditFormController] Không cập nhật được tài sản $code: $e');
    }
  }

  /// Xoá một bản nháp chưa ký. Phiếu đã ký (chính thức) không bao giờ bị xoá ở
  /// đây. Trả về `true` nếu đã xoá.
  Future<bool> deleteDraft(int id) async {
    try {
      final repository = ref.read(isarAuditRepositoryProvider);
      final records = await repository.getAllRecords();
      final record = records.where((r) => r.id == id).firstOrNull;
      if (record == null || !record.isDraft) return false;
      await repository.deleteRecord(id);
      // Bản nháp bị xoá thì xoá luôn các ảnh minh chứng của nó.
      final store = ref.read(evidencePhotoStoreProvider);
      for (final name in record.photoFiles ?? const <String>[]) {
        await store.delete(name);
      }
      return true;
    } catch (e) {
      debugPrint('[AuditFormController] Không xoá được bản nháp #$id: $e');
      return false;
    }
  }

  /// Chuỗi rỗng hoặc toàn khoảng trắng được lưu là `null`.
  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Đặt lại trạng thái ban đầu của form.
  void resetState() {
    state = const AuditFormState();
  }
}
