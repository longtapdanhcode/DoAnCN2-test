import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

/// Abstract repository định nghĩa contract cho việc đồng bộ dữ liệu
/// giữa Local Database (Isar) và Cloud Database / Storage (Supabase).
abstract class SyncRepository {
  /// Đẩy danh sách các bản ghi kiểm kê chưa đồng bộ lên Supabase Cloud Database.
  ///
  /// Sau khi đồng bộ thành công trên đám mây, trạng thái `isSynced` của các bản ghi
  /// tương ứng sẽ được cập nhật thành `true` trong cơ sở dữ liệu nội bộ.
  Future<void> syncPendingRecords(List<AuditRecordModel> records);

  /// Tải mảng byte ảnh chữ ký số lên Supabase Storage bucket
  /// và trả về URL truy cập ảnh trên đám mây.
  ///
  /// Trả về `null` nếu quá trình tải lên thất bại hoặc mảng byte rỗng.
  Future<String?> uploadSignature(List<int> bytes);

  /// Tải một ảnh minh chứng hiện trường (JPEG) lên Supabase Storage và trả về
  /// URL công khai. Ném lỗi nếu tải thất bại để phiếu ở lại hàng chờ đồng bộ.
  Future<String> uploadEvidencePhoto(List<int> bytes);
}
