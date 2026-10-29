import 'dart:convert';

import 'package:isar_plus/isar_plus.dart';

import '../../domain/entities/asset_status.dart';

part 'asset_model.g.dart';

/// Một tài sản trong danh mục, lưu trên máy bằng Isar.
///
/// Khóa chính là mã tài sản (ví dụ `TS-DC-0142`), nên lưu lại cùng một mã sẽ
/// ghi đè bản cũ thay vì tạo bản trùng.
@collection
class AssetModel {
  AssetModel(this.id);

  /// Mã tài sản, dùng làm khóa chính.
  final String id;

  @ignore
  String get code => id;

  String name = '';

  /// Loại thiết bị (ví dụ: "Thiết bị truyền động").
  String? category;

  /// Khu vực đặt tài sản (ví dụ: "Xưởng sản xuất A").
  String? area;

  /// Vị trí cụ thể trong khu vực.
  String? location;

  /// Số lượng theo danh mục.
  int quantity = 1;

  /// Mã tình trạng, xem [AssetStatus.code].
  String status = AssetStatus.good.code;

  /// Lần kiểm kê gần nhất; `null` nghĩa là chưa kiểm kê.
  DateTime? lastAuditAt;

  /// Thời điểm sửa gần nhất, dùng để giữ bản mới hơn khi đồng bộ.
  DateTime updatedAt = DateTime.now();

  /// `false` khi có thay đổi trên máy chưa đẩy lên Supabase.
  bool isSynced = true;

  /// Nội dung (JSON) của lần gần nhất bản trên máy và máy chủ khớp nhau, làm
  /// mốc gộp ba chiều khi cả hai bên cùng sửa.
  String? baseJson;

  /// Dòng máy chủ (JSON) khác phiên bản với thay đổi trên máy, chờ đối chiếu.
  String? conflictJson;

  @ignore
  bool get hasConflict => conflictJson != null;

  /// Bản máy chủ đang xung đột, hoặc `null` nếu không có.
  @ignore
  AssetModel? get conflictRemote {
    final json = conflictJson;
    if (json == null) return null;
    final value = jsonDecode(json);
    return value is Map<String, dynamic> ? AssetModel.fromJson(value) : null;
  }

  @ignore
  AssetStatus get assetStatus => AssetStatus.fromCode(status);

  /// Dữ liệu gửi lên bảng `assets` trên Supabase.
  Map<String, dynamic> toJson() => {
    'code': id,
    'name': name,
    'category': category,
    'area': area,
    'location': location,
    'quantity': quantity,
    'status': status,
    'last_audit_at': lastAuditAt?.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  /// Tạo từ một dòng của bảng `assets`; bản ghi tạo ra coi như đã đồng bộ.
  static AssetModel fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;

    return AssetModel(json['code'] as String)
      ..name = json['name'] as String? ?? ''
      ..category = json['category'] as String?
      ..area = json['area'] as String?
      ..location = json['location'] as String?
      ..quantity = (json['quantity'] as num?)?.toInt() ?? 1
      ..status = AssetStatus.fromCode(json['status'] as String?).code
      ..lastAuditAt = parse(json['last_audit_at'])
      ..updatedAt = parse(json['updated_at']) ?? DateTime.now()
      ..isSynced = true;
  }
}
