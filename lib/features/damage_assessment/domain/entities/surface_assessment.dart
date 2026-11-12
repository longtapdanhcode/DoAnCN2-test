import 'package:flutter/foundation.dart';

import 'damage_enums.dart';

/// Một vùng hư hỏng đã đo (do AI hoặc người kiểm kê nhập).
@immutable
class DamageMeasurement {
  const DamageMeasurement({
    required this.type,
    required this.quantity,
    this.source = MeasurementSource.ai,
    this.confidence,
  });

  final DamageType type;

  /// Khối lượng theo [DamageType.unit]: m² hoặc mét dài.
  final double quantity;
  final MeasurementSource source;

  /// Độ tin cậy của AI (0..1); `null` với số nhập tay.
  final double? confidence;

  Map<String, dynamic> toJson() => {
    'type': type.code,
    'quantity': quantity,
    'source': source.code,
    if (confidence != null) 'confidence': confidence,
  };

  static DamageMeasurement? fromJson(Map<String, dynamic> json) {
    final type = DamageType.fromCode(json['type'] as String?);
    final quantity = (json['quantity'] as num?)?.toDouble();
    if (type == null || quantity == null) return null;
    return DamageMeasurement(
      type: type,
      quantity: quantity,
      source: MeasurementSource.fromCode(json['source'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DamageMeasurement &&
      other.type == type &&
      other.quantity == quantity &&
      other.source == source &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(type, quantity, source, confidence);
}

/// Kết quả đánh giá một loại hư hỏng trên bề mặt (gộp mọi vùng cùng loại).
@immutable
class AssessedDamage {
  const AssessedDamage({
    required this.type,
    required this.measuredQuantity,
    required this.regionCount,
    required this.damageIndex,
    required this.severity,
    required this.billedQuantity,
    required this.fullSurface,
    this.unitPrice,
    this.estimatedCost,
    this.method = '',
    this.isSampleRate = false,
  });

  final DamageType type;

  /// Tổng khối lượng đo được của loại này.
  final double measuredQuantity;

  /// Số vùng đã gộp.
  final int regionCount;

  /// Chỉ số hư hại 0..100.
  final double damageIndex;
  final DamageSeverity severity;

  /// Khối lượng tính tiền: bằng số đo, hoặc cả bề mặt khi [fullSurface].
  final double billedQuantity;

  /// Hư hỏng vượt ngưỡng: đề xuất xử lý lại toàn bộ bề mặt.
  final bool fullSurface;

  /// `null` khi bảng đơn giá chưa có dòng phù hợp.
  final double? unitPrice;
  final double? estimatedCost;
  final String method;
  final bool isSampleRate;

  bool get hasPrice => estimatedCost != null;

  Map<String, dynamic> toJson() => {
    'type': type.code,
    'measured_quantity': measuredQuantity,
    'region_count': regionCount,
    'damage_index': damageIndex,
    'severity': severity.code,
    'billed_quantity': billedQuantity,
    'full_surface': fullSurface,
    if (unitPrice != null) 'unit_price': unitPrice,
    if (estimatedCost != null) 'estimated_cost': estimatedCost,
    'method': method,
    'is_sample_rate': isSampleRate,
  };

  static AssessedDamage? fromJson(Map<String, dynamic> json) {
    final type = DamageType.fromCode(json['type'] as String?);
    final severity = DamageSeverity.fromCode(json['severity'] as String?);
    if (type == null || severity == null) return null;
    double num0(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return AssessedDamage(
      type: type,
      measuredQuantity: num0('measured_quantity'),
      regionCount: (json['region_count'] as num?)?.toInt() ?? 1,
      damageIndex: num0('damage_index'),
      severity: severity,
      billedQuantity: num0('billed_quantity'),
      fullSurface: json['full_surface'] as bool? ?? false,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      method: json['method'] as String? ?? '',
      isSampleRate: json['is_sample_rate'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AssessedDamage &&
      other.type == type &&
      other.measuredQuantity == measuredQuantity &&
      other.regionCount == regionCount &&
      other.damageIndex == damageIndex &&
      other.severity == severity &&
      other.billedQuantity == billedQuantity &&
      other.fullSurface == fullSurface &&
      other.unitPrice == unitPrice &&
      other.estimatedCost == estimatedCost &&
      other.method == method &&
      other.isSampleRate == isSampleRate;

  @override
  int get hashCode => Object.hash(
    type,
    measuredQuantity,
    regionCount,
    damageIndex,
    severity,
    billedQuantity,
    fullSurface,
    unitPrice,
    estimatedCost,
    method,
    isSampleRate,
  );
}

/// Kết quả đánh giá một bề mặt, lưu kèm phiếu kiểm kê.
///
/// Lưu lại cả đơn giá tại thời điểm kiểm kê, nên báo cáo về sau không đổi khi
/// bảng giá thay đổi.
@immutable
class SurfaceAssessment {
  const SurfaceAssessment({
    required this.material,
    required this.surfaceAreaM2,
    this.measurements = const [],
    this.items = const [],
  });

  final SurfaceMaterial material;

  /// Diện tích bề mặt được kiểm tra (m²).
  final double surfaceAreaM2;

  /// Các vùng đã đo, giữ nguyên để mở lại phiếu và tính lại.
  final List<DamageMeasurement> measurements;

  /// Kết quả theo từng loại hư hỏng.
  final List<AssessedDamage> items;

  /// Tổng chi phí các hạng mục đã có đơn giá (VND).
  double get totalCost =>
      items.fold(0, (sum, i) => sum + (i.estimatedCost ?? 0));

  /// Số hạng mục chưa có đơn giá (tổng tiền đang thiếu phần này).
  int get unpricedCount => items.where((i) => !i.hasPrice).length;

  /// Chỉ số hư hại của cả bề mặt 0..100: cộng các loại, tối đa 100.
  double get damageIndex {
    final sum = items.fold<double>(0, (s, i) => s + i.damageIndex);
    return sum > 100 ? 100 : sum;
  }

  /// Điểm tình trạng 0..100 (100 là không hư hỏng).
  double get conditionScore => 100 - damageIndex;

  /// Mức nặng nhất, `null` khi không có hư hỏng.
  DamageSeverity? get worstSeverity {
    DamageSeverity? worst;
    for (final i in items) {
      if (worst == null || i.severity.index > worst.index) worst = i.severity;
    }
    return worst;
  }

  bool get usesSampleRates => items.any((i) => i.isSampleRate);

  Map<String, dynamic> toJson() => {
    'material': material.code,
    'surface_area_m2': surfaceAreaM2,
    'measurements': [for (final m in measurements) m.toJson()],
    'items': [for (final i in items) i.toJson()],
  };

  static SurfaceAssessment? fromJson(Map<String, dynamic> json) {
    final material = SurfaceMaterial.fromCode(json['material'] as String?);
    final area = (json['surface_area_m2'] as num?)?.toDouble();
    if (material == null || area == null) return null;
    List<T> list<T>(String key, T? Function(Map<String, dynamic>) parse) => [
      for (final e in (json[key] as List?) ?? const [])
        if (e is Map<String, dynamic>) ?parse(e),
    ];
    return SurfaceAssessment(
      material: material,
      surfaceAreaM2: area,
      measurements: list('measurements', DamageMeasurement.fromJson),
      items: list('items', AssessedDamage.fromJson),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SurfaceAssessment &&
      other.material == material &&
      other.surfaceAreaM2 == surfaceAreaM2 &&
      listEquals(other.measurements, measurements) &&
      listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(
    material,
    surfaceAreaM2,
    Object.hashAll(measurements),
    Object.hashAll(items),
  );
}
