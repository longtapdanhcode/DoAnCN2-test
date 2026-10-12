import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/audit_record_model.dart';
import '../../data/repositories/isar_audit_repository_impl.dart';

part 'audit_form_controller.g.dart';

/// Trạng thái của biểu mẫu kiểm kê động.
enum AuditFormStatus {
  initial,
  saving,
  success,
  error,
}

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

  AuditFormState copyWith({
    AuditFormStatus? status,
    String? errorMessage,
  }) {
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
    required int quantity,
    List<int>? signatureBytes,
  }) async {
    state = state.copyWith(
      status: AuditFormStatus.saving,
      errorMessage: null,
    );

    try {
      final repository = ref.read(isarAuditRepositoryProvider);

      final record = AuditRecordModel(0)
        ..scanCode = scanCode.trim()
        ..aiDetectedLabel = (aiLabel != null && aiLabel.trim().isNotEmpty)
            ? aiLabel.trim()
            : null
        ..quantity = quantity
        ..signatureBytes = signatureBytes
        ..timestamp = DateTime.now()
        ..isSynced = false;

      await repository.saveRecord(record);

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

  /// Đặt lại trạng thái ban đầu của form.
  void resetState() {
    state = const AuditFormState();
  }
}
