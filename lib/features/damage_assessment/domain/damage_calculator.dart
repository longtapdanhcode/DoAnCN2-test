import 'package:flutter/foundation.dart';

import 'package:field_inventory_edge_ai/features/offline_audit/domain/entities/audit_condition.dart';

import 'entities/damage_enums.dart';
import 'entities/repair_rate.dart';
import 'entities/surface_assessment.dart';

/// Các ngưỡng dùng để tính chỉ số và mức độ. Giá trị mặc định là điểm xuất
/// phát, cần chỉnh lại sau khi đối chiếu với đánh giá thực tế của nhà trường.
@immutable
class AssessmentConfig {
  const AssessmentConfig({
    this.moderateFrom = 5,
    this.severeFrom = 20,
    this.fullSurfaceFrom = 40,
    this.crackFullDensity = 2.0,
  }) : assert(0 < moderateFrom && moderateFrom < severeFrom),
       assert(severeFrom <= 100 && fullSurfaceFrom <= 100),
       assert(crackFullDensity > 0);

  /// Chỉ số (0..100) từ đó tính là mức Vừa.
  final double moderateFrom;

  /// Chỉ số từ đó tính là mức Nặng.
  final double severeFrom;

  /// Chỉ số từ đó đề xuất xử lý lại cả bề mặt (chỉ với loại đo theo m²).
  final double fullSurfaceFrom;

  /// Mật độ vết nứt (mét nứt trên mỗi m² bề mặt) ứng với chỉ số 100.
  final double crackFullDensity;
}

/// Tính chỉ số hư hại, mức độ và chi phí sửa chữa cho một bề mặt.
///
/// - Loại đo theo m²: chỉ số = diện tích hư ÷ diện tích bề mặt × 100.
/// - Vết nứt (đo theo mét): chỉ số = (mét nứt ÷ m² bề mặt) ÷
///   [AssessmentConfig.crackFullDensity] × 100.
/// - Các vùng cùng loại được cộng lại trước khi tính, nên không bị tính tiền
///   hai lần khi đề xuất xử lý cả bề mặt.
/// - Chi phí = khối lượng tính tiền × đơn giá theo (chất liệu, loại, mức độ).
class DamageCalculator {
  const DamageCalculator(this.rates, {this.config = const AssessmentConfig()});

  final RepairRateTable rates;
  final AssessmentConfig config;

  SurfaceAssessment assess({
    required SurfaceMaterial material,
    required double surfaceAreaM2,
    required List<DamageMeasurement> measurements,
  }) {
    if (!(surfaceAreaM2 > 0)) {
      throw ArgumentError.value(
        surfaceAreaM2,
        'surfaceAreaM2',
        'Diện tích bề mặt phải lớn hơn 0',
      );
    }
    for (final m in measurements) {
      if (m.quantity < 0 || m.quantity.isNaN) {
        throw ArgumentError.value(
          m.quantity,
          'measurements',
          'Khối lượng hư hỏng không được âm',
        );
      }
    }

    final totals = <DamageType, double>{};
    final counts = <DamageType, int>{};
    for (final m in measurements) {
      if (m.quantity == 0) continue;
      totals[m.type] = (totals[m.type] ?? 0) + m.quantity;
      counts[m.type] = (counts[m.type] ?? 0) + 1;
    }

    final items = [
      for (final type in DamageType.values)
        if (totals.containsKey(type))
          _assessType(
            material,
            surfaceAreaM2,
            type,
            totals[type]!,
            counts[type]!,
          ),
    ];

    return SurfaceAssessment(
      material: material,
      surfaceAreaM2: surfaceAreaM2,
      measurements: List.unmodifiable(measurements),
      items: List.unmodifiable(items),
    );
  }

  AssessedDamage _assessType(
    SurfaceMaterial material,
    double surfaceArea,
    DamageType type,
    double measured,
    int regions,
  ) {
    final index = damageIndexFor(type, measured, surfaceArea);
    final severity = severityFor(index);
    final isArea = type.unit == MeasureUnit.squareMeter;
    final fullSurface = isArea && index >= config.fullSurfaceFrom;
    // Vùng đo lớn hơn bề mặt (sai số đo) cho chỉ số 100, nên rơi vào nhánh
    // xử lý cả bề mặt và không bị tính quá diện tích bề mặt.
    final billed = fullSurface ? surfaceArea : measured;

    final rate = rates.lookup(material, type, severity);
    return AssessedDamage(
      type: type,
      measuredQuantity: measured,
      regionCount: regions,
      damageIndex: index,
      severity: severity,
      billedQuantity: billed,
      fullSurface: fullSurface,
      unitPrice: rate?.unitPrice,
      estimatedCost: rate == null
          ? null
          : (billed * rate.unitPrice).roundToDouble(),
      method: rate?.method ?? '',
      isSampleRate: rate?.isSample ?? false,
    );
  }

  /// Chỉ số hư hại 0..100 của một loại trên bề mặt [surfaceArea] m².
  double damageIndexFor(DamageType type, double measured, double surfaceArea) {
    final ratio = type.unit == MeasureUnit.meter
        ? (measured / surfaceArea) / config.crackFullDensity
        : measured / surfaceArea;
    final index = ratio * 100;
    return index > 100 ? 100 : index;
  }

  DamageSeverity severityFor(double index) {
    if (index >= config.severeFrom) return DamageSeverity.severe;
    if (index >= config.moderateFrom) return DamageSeverity.moderate;
    return DamageSeverity.light;
  }
}

/// Tình trạng ghi vào phiếu, suy ra từ mức hư hỏng nặng nhất.
AuditCondition conditionForAssessment(SurfaceAssessment assessment) =>
    switch (assessment.worstSeverity) {
      null => AuditCondition.good,
      DamageSeverity.light || DamageSeverity.moderate => AuditCondition.check,
      DamageSeverity.severe => AuditCondition.damaged,
    };
