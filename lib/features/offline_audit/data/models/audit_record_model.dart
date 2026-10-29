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

  /// Tên tài sản do kiểm kê viên nhập (ví dụ: "Động cơ điện Siemens 3 pha").
  String? assetName;

  /// Số lượng sản phẩm kiểm kê.
  int quantity = 0;

  /// Khu vực kiểm kê (ví dụ: "Xưởng sản xuất A").
  String? area;

  /// Vị trí cụ thể trong khu vực (ví dụ: "Dây chuyền 02 • Kệ A3").
  String? location;

  /// Mã tình trạng thực tế, xem [AuditCondition.code].
  String? condition;

  /// Ghi chú hiện trường của kiểm kê viên.
  String? notes;

  /// Dữ liệu ảnh chữ ký số dưới dạng byte PNG.
  List<int>? signatureBytes;

  /// Họ tên người ký xác nhận phiếu.
  String? signerName;

  /// Vai trò của người ký (ví dụ: "Kiểm kê viên").
  String? signerRole;

  /// Tên tệp các ảnh minh chứng hiện trường (tối đa 3), lưu bởi
  /// `EvidencePhotoStore`. `null` hoặc rỗng nếu phiếu không có ảnh.
  List<String>? photoFiles;

  /// Thời điểm tạo bản ghi.
  DateTime? timestamp;

  /// Bản nháp = phiếu chưa có chữ ký xác nhận. Bản nháp chỉ nằm trên máy:
  /// không đồng bộ, không vào báo cáo và chưa tính là đã kiểm kê.
  @ignore
  bool get isDraft => signatureBytes == null || signatureBytes!.isEmpty;

  /// Phiếu có kèm ảnh minh chứng hiện trường.
  @ignore
  bool get hasPhotos => photoFiles?.isNotEmpty ?? false;

  /// Cờ đánh dấu bản ghi đã được đồng bộ lên Supabase hay chưa.
  ///
  /// Mặc định là `false` – nghĩa là chưa đồng bộ (offline-first).
  bool isSynced = false;

  /// Bản sao với [id] mới, giữ **mọi** trường dữ liệu (dùng khi gán id tự tăng
  /// lúc lưu phiếu mới). Thêm trường mới vào lớp này thì phải thêm ở đây.
  AuditRecordModel copyWithId(int id) => AuditRecordModel(id)
    ..scanCode = scanCode
    ..aiDetectedLabel = aiDetectedLabel
    ..assetName = assetName
    ..quantity = quantity
    ..area = area
    ..location = location
    ..condition = condition
    ..notes = notes
    ..signatureBytes = signatureBytes
    ..signerName = signerName
    ..signerRole = signerRole
    ..photoFiles = photoFiles
    ..timestamp = timestamp
    ..isSynced = isSynced;
}
