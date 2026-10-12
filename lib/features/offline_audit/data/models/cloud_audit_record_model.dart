import 'audit_record_model.dart';

/// Data model đại diện cho bản ghi kiểm kê lưu trữ trên Supabase Cloud Database.
///
/// Khác với [AuditRecordModel] cục bộ (sử dụng integer auto-increment và byte array),
/// [CloudAuditRecordModel] sử dụng UUID làm primary key và URL Storage cho ảnh chữ ký.
class CloudAuditRecordModel {
  /// Mã định danh duy nhất của bản ghi trên đám mây (UUID v4).
  final String id;

  /// Mã QR / Barcode quét được từ camera.
  final String scanCode;

  /// Nhãn nhận diện do On-Device Edge AI phát hiện (nếu có).
  final String? aiDetectedLabel;

  /// Số lượng vật tư / thiết bị kiểm kê.
  final int quantity;

  /// Thời điểm tạo bản ghi theo định dạng chuẩn ISO-8601 UTC.
  final String timestamp;

  /// Đường dẫn công khai hoặc signed URL của ảnh chữ ký lưu trên Supabase Storage bucket.
  final String? signatureUrl;

  const CloudAuditRecordModel({
    required this.id,
    required this.scanCode,
    this.aiDetectedLabel,
    required this.quantity,
    required this.timestamp,
    this.signatureUrl,
  });

  /// Chuyển đổi từ Map / JSON trả về từ Supabase PostgREST
  factory CloudAuditRecordModel.fromJson(Map<String, dynamic> json) {
    return CloudAuditRecordModel(
      id: json['id'] as String? ?? '',
      scanCode:
          json['scan_code'] as String? ?? json['scanCode'] as String? ?? '',
      aiDetectedLabel: json['ai_detected_label'] as String? ??
          json['aiDetectedLabel'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] as String? ?? '',
      signatureUrl: json['signature_url'] as String? ??
          json['signatureUrl'] as String?,
    );
  }

  /// Xuất ra Map / JSON theo chuẩn snake_case để lưu trữ vào bảng Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scan_code': scanCode,
      if (aiDetectedLabel != null) 'ai_detected_label': aiDetectedLabel,
      'quantity': quantity,
      'timestamp': timestamp,
      if (signatureUrl != null) 'signature_url': signatureUrl,
    };
  }

  /// Tạo instance [CloudAuditRecordModel] từ [AuditRecordModel] offline
  factory CloudAuditRecordModel.fromAuditRecordModel(
    AuditRecordModel record, {
    required String id,
    String? signatureUrl,
  }) {
    return CloudAuditRecordModel(
      id: id,
      scanCode: record.scanCode ?? '',
      aiDetectedLabel: record.aiDetectedLabel,
      quantity: record.quantity,
      timestamp:
          (record.timestamp ?? DateTime.now()).toUtc().toIso8601String(),
      signatureUrl: signatureUrl,
    );
  }

  CloudAuditRecordModel copyWith({
    String? id,
    String? scanCode,
    String? aiDetectedLabel,
    int? quantity,
    String? timestamp,
    String? signatureUrl,
  }) {
    return CloudAuditRecordModel(
      id: id ?? this.id,
      scanCode: scanCode ?? this.scanCode,
      aiDetectedLabel: aiDetectedLabel ?? this.aiDetectedLabel,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }

  @override
  String toString() {
    return 'CloudAuditRecordModel(id: $id, scanCode: $scanCode, aiDetectedLabel: $aiDetectedLabel, quantity: $quantity, timestamp: $timestamp, signatureUrl: $signatureUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CloudAuditRecordModel &&
        other.id == id &&
        other.scanCode == scanCode &&
        other.aiDetectedLabel == aiDetectedLabel &&
        other.quantity == quantity &&
        other.timestamp == timestamp &&
        other.signatureUrl == signatureUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      scanCode,
      aiDetectedLabel,
      quantity,
      timestamp,
      signatureUrl,
    );
  }
}
