import 'package:isar_plus/isar_plus.dart';

part 'audit_record_model.g.dart';

/// Isar Collection đại diện cho một bản ghi kiểm kê (audit record).
///
/// Mỗi record chứa thông tin quét mã (QR/Barcode), nhãn AI nhận diện,
/// số lượng, thời gian và trạng thái đồng bộ lên Supabase.
///
/// Với `isar_plus`, ID sử dụng `final int id` và auto-increment
/// được xử lý thông qua `collection.autoIncrement()` tại thời điểm insert.
@collection
class AuditRecordModel {
  /// Primary key – truyền qua constructor.
  /// Sử dụng `isar.auditRecordModels.autoIncrement()` khi tạo record mới.
  AuditRecordModel(this.id, {this.signatureBytes});

  final int id;

  /// Mã QR / Barcode quét được từ camera.
  String? scanCode;

  /// Nhãn do AI Edge nhận diện được (có thể null nếu chưa chạy AI).
  String? aiDetectedLabel;

  /// Số lượng sản phẩm kiểm kê.
  int quantity = 0;

  /// Dữ liệu ảnh chữ ký số dưới dạng byte PNG.
  List<int>? signatureBytes;

  /// Thời điểm tạo bản ghi.
  DateTime? timestamp;

  /// Cờ đánh dấu bản ghi đã được đồng bộ lên Supabase hay chưa.
  ///
  /// Mặc định là `false` – nghĩa là chưa đồng bộ (offline-first).
  bool isSynced = false;
}
