import 'package:flutter/foundation.dart';

import 'damage_enums.dart';

/// Một dòng trong bảng đơn giá sửa chữa (`repair_cost_rates` trên Supabase).
@immutable
class RepairRate {
  const RepairRate({
    this.material,
    required this.damageType,
    required this.severity,
    required this.unitPrice,
    this.method = '',
    this.isSample = false,
  });

  /// `null`: áp dụng cho mọi chất liệu chưa có dòng riêng.
  final SurfaceMaterial? material;
  final DamageType damageType;
  final DamageSeverity severity;

  /// Đơn giá (VND) cho một đơn vị [unit].
  final double unitPrice;

  /// Cách xử lý, ví dụ "Cạo, chống thấm, sơn lại".
  final String method;

  /// Giá minh hoạ, chưa phải giá thật của nhà trường.
  final bool isSample;

  /// Đơn vị tính tiền, luôn theo loại hư hỏng.
  MeasureUnit get unit => damageType.unit;

  /// Đọc một dòng của bảng `repair_cost_rates`; trả `null` nếu dòng sai mã.
  static RepairRate? fromJson(Map<String, dynamic> json) {
    final type = DamageType.fromCode(json['damage_type'] as String?);
    final severity = DamageSeverity.fromCode(json['severity'] as String?);
    final price = (json['unit_price'] as num?)?.toDouble();
    if (type == null || severity == null || price == null || price < 0) {
      return null;
    }
    final materialCode = json['material'] as String?;
    final material = SurfaceMaterial.fromCode(materialCode);
    // Mã chất liệu lạ: bỏ dòng thay vì coi như "mọi chất liệu".
    if (materialCode != null && material == null) return null;
    return RepairRate(
      material: material,
      damageType: type,
      severity: severity,
      unitPrice: price,
      method: json['method'] as String? ?? '',
      isSample: json['is_sample'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'material': material?.code,
    'damage_type': damageType.code,
    'severity': severity.code,
    'unit': unit.code,
    'unit_price': unitPrice,
    'method': method,
    'is_sample': isSample,
  };

  @override
  bool operator ==(Object other) =>
      other is RepairRate &&
      other.material == material &&
      other.damageType == damageType &&
      other.severity == severity &&
      other.unitPrice == unitPrice &&
      other.method == method &&
      other.isSample == isSample;

  @override
  int get hashCode =>
      Object.hash(material, damageType, severity, unitPrice, method, isSample);
}

/// Bảng đơn giá app dùng để tính tiền, kèm nơi lấy về.
@immutable
class RepairRateTable {
  const RepairRateTable(this.rates, {required this.source, this.fetchedAt});

  final List<RepairRate> rates;
  final RepairRateSource source;

  /// Lần tải bảng từ Supabase (với nguồn cache là lần tải trước đó).
  final DateTime? fetchedAt;

  /// Có dòng nào là giá minh hoạ không (để báo cáo ghi chú).
  bool get hasSampleRates => rates.any((r) => r.isSample);

  /// Đơn giá cho tổ hợp đã cho: ưu tiên dòng đúng chất liệu, sau đó tới dòng
  /// chung (không ghi chất liệu). `null` nếu bảng chưa có giá.
  RepairRate? lookup(
    SurfaceMaterial material,
    DamageType type,
    DamageSeverity severity,
  ) {
    RepairRate? general;
    for (final r in rates) {
      if (r.damageType != type || r.severity != severity) continue;
      if (r.material == material) return r;
      if (r.material == null) general ??= r;
    }
    return general;
  }
}

enum RepairRateSource {
  /// Vừa tải từ Supabase.
  remote,

  /// Bản đã lưu trên máy từ lần tải trước (đang ngoại tuyến).
  cache,

  /// Bảng giá minh hoạ đóng gói sẵn trong app (chưa từng tải được).
  sample,
}
