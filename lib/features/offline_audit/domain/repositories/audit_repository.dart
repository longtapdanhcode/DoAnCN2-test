import 'dart:typed_data';

import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

/// Abstract repository cho các thao tác CRUD trên bản ghi kiểm kê.
///
/// Lớp domain này định nghĩa contract mà bất kỳ data-source nào
/// (Isar local, remote API, v.v.) đều phải tuân theo.
abstract class AuditRepository {
  /// Lưu một bản ghi kiểm kê mới vào database.
  Future<void> saveRecord(AuditRecordModel record);

  /// Lấy toàn bộ danh sách bản ghi kiểm kê đã lưu.
  Future<List<AuditRecordModel>> getAllRecords();

  /// Tạo và xuất file PDF báo cáo kiểm kê hiện trường.
  Future<Uint8List> exportPdfReport();
}
