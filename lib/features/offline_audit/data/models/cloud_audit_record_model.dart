import 'dart:math';

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

  /// Tên tài sản do kiểm kê viên nhập.
  final String? assetName;

  /// Khu vực kiểm kê.
  final String? area;

  /// Vị trí cụ thể trong khu vực.
  final String? location;

  /// Mã tình trạng thực tế (`good`, `check`, `damaged`).
  final String? condition;

  /// Ghi chú hiện trường.
  final String? notes;

  /// Thời điểm tạo bản ghi theo định dạng chuẩn ISO-8601 UTC.
  final String timestamp;

  /// Đường dẫn công khai hoặc signed URL của ảnh chữ ký lưu trên Supabase Storage bucket.
  final String? signatureUrl;

  /// Họ tên người ký xác nhận.
  final String? signerName;

  /// URL công khai các ảnh minh chứng hiện trường trên Supabase Storage.
  final List<String> photoUrls;

  /// Vai trò của người ký.
  final String? signerRole;

  const CloudAuditRecordModel({
    required this.id,
    required this.scanCode,
    this.aiDetectedLabel,
    required this.quantity,
    this.assetName,
    this.area,
    this.location,
    this.condition,
    this.notes,
    required this.timestamp,
    this.signatureUrl,
    this.photoUrls = const [],
    this.signerName,
    this.signerRole,
  });

  /// Chuyển đổi từ Map / JSON trả về từ Supabase PostgREST
  factory CloudAuditRecordModel.fromJson(Map<String, dynamic> json) {
    return CloudAuditRecordModel(
      id: json['id'] as String? ?? '',
      scanCode:
          json['scan_code'] as String? ?? json['scanCode'] as String? ?? '',
      aiDetectedLabel:
          json['ai_detected_label'] as String? ??
          json['aiDetectedLabel'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      assetName: json['asset_name'] as String?,
      area: json['area'] as String?,
      location: json['location'] as String?,
      condition: json['condition'] as String?,
      notes: json['notes'] as String?,
      timestamp: json['timestamp'] as String? ?? '',
      signatureUrl:
          json['signature_url'] as String? ?? json['signatureUrl'] as String?,
      signerName: json['signer_name'] as String?,
      signerRole: json['signer_role'] as String?,
      photoUrls: [
        for (final u in (json['photo_urls'] as List?) ?? const [])
          if (u is String) u,
      ],
    );
  }

  /// Xuất ra Map / JSON theo chuẩn snake_case để lưu trữ vào bảng Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scan_code': scanCode,
      if (aiDetectedLabel != null) 'ai_detected_label': aiDetectedLabel,
      'quantity': quantity,
      if (assetName != null) 'asset_name': assetName,
      if (area != null) 'area': area,
      if (location != null) 'location': location,
      if (condition != null) 'condition': condition,
      if (notes != null) 'notes': notes,
      'timestamp': timestamp,
      if (signatureUrl != null) 'signature_url': signatureUrl,
      if (signerName != null) 'signer_name': signerName,
      if (signerRole != null) 'signer_role': signerRole,
      // Chỉ gửi khi có ảnh: phiếu không ảnh vẫn đồng bộ được trước khi bảng có cột này.
      if (photoUrls.isNotEmpty) 'photo_urls': photoUrls,
    };
  }

  /// Tạo instance [CloudAuditRecordModel] từ [AuditRecordModel] offline
  factory CloudAuditRecordModel.fromAuditRecordModel(
    AuditRecordModel record, {
    String? id,
    String? signatureUrl,
    List<String> photoUrls = const [],
  }) {
    return CloudAuditRecordModel(
      id: id ?? _generateUuidV4(),
      scanCode: record.scanCode ?? '',
      aiDetectedLabel: record.aiDetectedLabel,
      quantity: record.quantity,
      assetName: record.assetName,
      area: record.area,
      location: record.location,
      condition: record.condition,
      notes: record.notes,
      timestamp: (record.timestamp ?? DateTime.now()).toUtc().toIso8601String(),
      signatureUrl: signatureUrl,
      signerName: record.signerName,
      signerRole: record.signerRole,
      photoUrls: photoUrls,
    );
  }

  static String _generateUuidV4() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // RFC4122 version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC4122 variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  CloudAuditRecordModel copyWith({
    String? id,
    String? scanCode,
    String? aiDetectedLabel,
    int? quantity,
    String? assetName,
    String? area,
    String? location,
    String? condition,
    String? notes,
    String? timestamp,
    String? signatureUrl,
    String? signerName,
    String? signerRole,
    List<String>? photoUrls,
  }) {
    return CloudAuditRecordModel(
      id: id ?? this.id,
      scanCode: scanCode ?? this.scanCode,
      aiDetectedLabel: aiDetectedLabel ?? this.aiDetectedLabel,
      quantity: quantity ?? this.quantity,
      assetName: assetName ?? this.assetName,
      area: area ?? this.area,
      location: location ?? this.location,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      signerName: signerName ?? this.signerName,
      signerRole: signerRole ?? this.signerRole,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  @override
  String toString() {
    return 'CloudAuditRecordModel(id: $id, scanCode: $scanCode, aiDetectedLabel: $aiDetectedLabel, quantity: $quantity, assetName: $assetName, area: $area, location: $location, condition: $condition, notes: $notes, timestamp: $timestamp, signatureUrl: $signatureUrl, signerName: $signerName, signerRole: $signerRole, photoUrls: $photoUrls)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CloudAuditRecordModel &&
        other.id == id &&
        other.scanCode == scanCode &&
        other.aiDetectedLabel == aiDetectedLabel &&
        other.quantity == quantity &&
        other.assetName == assetName &&
        other.area == area &&
        other.location == location &&
        other.condition == condition &&
        other.notes == notes &&
        other.timestamp == timestamp &&
        other.signatureUrl == signatureUrl &&
        other.signerName == signerName &&
        other.signerRole == signerRole &&
        _listEquals(other.photoUrls, photoUrls);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      scanCode,
      aiDetectedLabel,
      quantity,
      assetName,
      area,
      location,
      condition,
      notes,
      timestamp,
      signatureUrl,
      signerName,
      signerRole,
      Object.hashAll(photoUrls),
    );
  }
}
