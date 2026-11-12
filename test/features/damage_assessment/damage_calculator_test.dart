import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/damage_assessment/data/sample_repair_rates.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_calculator.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/repair_rate.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/surface_assessment.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/entities/audit_condition.dart';

DamageMeasurement m(DamageType t, double q, {MeasurementSource? source}) =>
    DamageMeasurement(
      type: t,
      quantity: q,
      source: source ?? MeasurementSource.ai,
    );

void main() {
  const sample = RepairRateTable(
    sampleRepairRates,
    source: RepairRateSource.sample,
  );
  const calc = DamageCalculator(sample);

  group('Chỉ số hư hại và mức độ', () {
    test('Loại đo theo m²: chỉ số = diện tích hư / diện tích bề mặt', () {
      final r = calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 10,
        measurements: [m(DamageType.waterMold, 1)],
      );
      final item = r.items.single;
      expect(item.damageIndex, closeTo(10, 1e-9));
      expect(item.severity, DamageSeverity.moderate);
      expect(item.fullSurface, isFalse);
      expect(item.billedQuantity, 1);
    });

    test('Vết nứt: chỉ số theo mật độ mét nứt trên m²', () {
      // 2 m nứt trên 10 m² = 0.2 m/m²; mức 100 ứng với 2 m/m² => chỉ số 10.
      final item = calc
          .assess(
            material: SurfaceMaterial.paintedWall,
            surfaceAreaM2: 10,
            measurements: [m(DamageType.crack, 2)],
          )
          .items
          .single;
      expect(item.damageIndex, closeTo(10, 1e-9));
      expect(item.severity, DamageSeverity.moderate);
      // Vết nứt luôn tính tiền theo mét đo được, không theo cả bề mặt.
      expect(item.billedQuantity, 2);
      expect(item.estimatedCost, 2 * 150000);
    });

    test('Ranh giới ngưỡng: 5 là Vừa, 20 là Nặng', () {
      expect(calc.severityFor(4.99), DamageSeverity.light);
      expect(calc.severityFor(5), DamageSeverity.moderate);
      expect(calc.severityFor(19.99), DamageSeverity.moderate);
      expect(calc.severityFor(20), DamageSeverity.severe);
    });

    test('Chỉ số không vượt 100', () {
      expect(calc.damageIndexFor(DamageType.rust, 50, 10), 100);
      expect(calc.damageIndexFor(DamageType.crack, 1000, 1), 100);
    });

    test('Ngưỡng tuỳ chỉnh qua AssessmentConfig', () {
      const strict = DamageCalculator(
        sample,
        config: AssessmentConfig(moderateFrom: 1, severeFrom: 3),
      );
      expect(strict.severityFor(2), DamageSeverity.moderate);
      expect(strict.severityFor(3), DamageSeverity.severe);
    });
  });

  group('Chi phí', () {
    test('Chi phí = khối lượng × đơn giá theo mức độ', () {
      final r = calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 20,
        measurements: [m(DamageType.peelingPaint, 0.5)], // 2.5% => Nhẹ
      );
      expect(r.items.single.severity, DamageSeverity.light);
      expect(r.items.single.unitPrice, 60000);
      expect(r.totalCost, 30000);
    });

    test('Vượt ngưỡng xử lý toàn bộ: tính tiền cả bề mặt', () {
      final item = calc
          .assess(
            material: SurfaceMaterial.paintedWall,
            surfaceAreaM2: 10,
            measurements: [m(DamageType.waterMold, 4.5)], // 45%
          )
          .items
          .single;
      expect(item.severity, DamageSeverity.severe);
      expect(item.fullSurface, isTrue);
      expect(item.billedQuantity, 10);
      expect(item.estimatedCost, 10 * 380000);
    });

    test('Nhiều vùng cùng loại được gộp, không tính trùng cả bề mặt', () {
      final r = calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 10,
        measurements: [
          m(DamageType.waterMold, 2.5),
          m(DamageType.waterMold, 2.5),
        ],
      );
      expect(r.items, hasLength(1));
      final item = r.items.single;
      expect(item.regionCount, 2);
      expect(item.measuredQuantity, 5);
      expect(item.billedQuantity, 10);
      expect(r.totalCost, 10 * 380000);
    });

    test('Vùng đo lớn hơn bề mặt: không tính quá diện tích bề mặt', () {
      final item = calc
          .assess(
            material: SurfaceMaterial.metal,
            surfaceAreaM2: 2,
            measurements: [m(DamageType.rust, 3)],
          )
          .items
          .single;
      expect(item.damageIndex, 100);
      expect(item.fullSurface, isTrue);
      expect(item.billedQuantity, 2);
    });

    test('Ưu tiên đơn giá riêng của chất liệu, sau đó tới giá chung', () {
      const table = RepairRateTable([
        RepairRate(
          damageType: DamageType.crack,
          severity: DamageSeverity.light,
          unitPrice: 100,
        ),
        RepairRate(
          material: SurfaceMaterial.tile,
          damageType: DamageType.crack,
          severity: DamageSeverity.light,
          unitPrice: 900,
          method: 'Thay gạch',
        ),
      ], source: RepairRateSource.remote);
      const c = DamageCalculator(table);
      double cost(SurfaceMaterial mat) => c
          .assess(
            material: mat,
            surfaceAreaM2: 100,
            measurements: [m(DamageType.crack, 1)],
          )
          .totalCost;
      expect(cost(SurfaceMaterial.tile), 900);
      expect(cost(SurfaceMaterial.concrete), 100);
    });

    test('Thiếu đơn giá: hạng mục không có tiền và được đếm riêng', () {
      const empty = DamageCalculator(
        RepairRateTable([], source: RepairRateSource.remote),
      );
      final r = empty.assess(
        material: SurfaceMaterial.wood,
        surfaceAreaM2: 5,
        measurements: [m(DamageType.peelingPaint, 1)],
      );
      expect(r.items.single.hasPrice, isFalse);
      expect(r.totalCost, 0);
      expect(r.unpricedCount, 1);
    });

    test('Giá minh hoạ được đánh dấu để báo cáo ghi chú', () {
      final r = calc.assess(
        material: SurfaceMaterial.concrete,
        surfaceAreaM2: 10,
        measurements: [m(DamageType.crack, 0.5)],
      );
      expect(r.usesSampleRates, isTrue);
    });
  });

  group('Tổng hợp bề mặt', () {
    test('Không có hư hỏng: điểm 100, tình trạng Tốt', () {
      final r = calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 12,
        measurements: const [],
      );
      expect(r.items, isEmpty);
      expect(r.conditionScore, 100);
      expect(r.worstSeverity, isNull);
      expect(conditionForAssessment(r), AuditCondition.good);
    });

    test('Bỏ qua số đo bằng 0', () {
      final r = calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 12,
        measurements: [m(DamageType.rust, 0)],
      );
      expect(r.items, isEmpty);
    });

    test('Chỉ số bề mặt cộng các loại, điểm = 100 - chỉ số', () {
      final r = calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 10,
        measurements: [
          m(DamageType.waterMold, 1), // 10
          m(DamageType.peelingPaint, 0.3), // 3
        ],
      );
      expect(r.damageIndex, closeTo(13, 1e-9));
      expect(r.conditionScore, closeTo(87, 1e-9));
      expect(r.worstSeverity, DamageSeverity.moderate);
      expect(conditionForAssessment(r), AuditCondition.check);
      // Thứ tự hạng mục theo thứ tự lớp của model.
      expect(r.items.map((i) => i.type), [
        DamageType.waterMold,
        DamageType.peelingPaint,
      ]);
    });

    test('Có hạng mục Nặng: tình trạng Hư hỏng', () {
      final r = calc.assess(
        material: SurfaceMaterial.metal,
        surfaceAreaM2: 2,
        measurements: [m(DamageType.rust, 0.5)], // 25%
      );
      expect(conditionForAssessment(r), AuditCondition.damaged);
    });

    test('Báo lỗi khi diện tích bề mặt không hợp lệ hoặc số đo âm', () {
      expect(
        () => calc.assess(
          material: SurfaceMaterial.paintedWall,
          surfaceAreaM2: 0,
          measurements: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => calc.assess(
          material: SurfaceMaterial.paintedWall,
          surfaceAreaM2: 10,
          measurements: [m(DamageType.crack, -1)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('JSON', () {
    test('SurfaceAssessment giữ nguyên qua toJson/fromJson', () {
      final r = calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 10,
        measurements: [
          m(DamageType.crack, 1.2),
          const DamageMeasurement(
            type: DamageType.waterMold,
            quantity: 4.5,
            confidence: 0.81,
          ),
          m(DamageType.rust, 0.2, source: MeasurementSource.manual),
        ],
      );
      expect(SurfaceAssessment.fromJson(r.toJson()), r);
    });

    test('Bỏ các phần tử sai mã khi đọc', () {
      final parsed = SurfaceAssessment.fromJson({
        'material': 'painted_wall',
        'surface_area_m2': 10,
        'measurements': [
          {'type': 'khong_co', 'quantity': 1},
          {'type': 'vet_nut', 'quantity': 1},
        ],
        'items': [],
      });
      expect(parsed!.measurements, hasLength(1));
      expect(SurfaceAssessment.fromJson({'material': 'x'}), isNull);
    });

    test('RepairRate đọc dòng Supabase, bỏ dòng sai mã', () {
      expect(
        RepairRate.fromJson({
          'material': null,
          'damage_type': 'gi_set',
          'severity': 'severe',
          'unit_price': 450000,
          'method': 'Thay',
          'is_sample': true,
        }),
        const RepairRate(
          damageType: DamageType.rust,
          severity: DamageSeverity.severe,
          unitPrice: 450000,
          method: 'Thay',
          isSample: true,
        ),
      );
      expect(
        RepairRate.fromJson({
          'material': 'da_hoa_cuong',
          'damage_type': 'gi_set',
          'severity': 'severe',
          'unit_price': 1,
        }),
        isNull,
      );
    });

    test('Bảng mẫu có đủ 4 loại × 3 mức', () {
      for (final t in DamageType.values) {
        for (final s in DamageSeverity.values) {
          expect(
            sample.lookup(SurfaceMaterial.paintedWall, t, s),
            isNotNull,
            reason: '${t.code}/${s.code}',
          );
        }
      }
    });
  });
}
