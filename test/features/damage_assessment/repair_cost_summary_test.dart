import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/damage_assessment/data/sample_repair_rates.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_calculator.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/repair_rate.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/surface_assessment.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/repair_cost_summary.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

const _calc = DamageCalculator(
  RepairRateTable(sampleRepairRates, source: RepairRateSource.sample),
);

AuditRecordModel record(
  int id, {
  String? code,
  String? building,
  String? room,
  double area = 10,
  List<DamageMeasurement> damages = const [],
  DateTime? at,
  bool signed = true,
  bool assessed = true,
}) {
  final r = AuditRecordModel(id, signatureBytes: signed ? Uint8List(1) : null)
    ..scanCode = code
    ..assetName = 'Bề mặt $id'
    ..area = building
    ..location = room
    ..timestamp = at ?? DateTime(2026, 11, id);
  if (assessed) {
    r.applyAssessment(
      _calc.assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: area,
        measurements: damages,
      ),
    );
  }
  return r;
}

const _water1 = DamageMeasurement(type: DamageType.waterMold, quantity: 1);
const _water3 = DamageMeasurement(type: DamageType.waterMold, quantity: 3);
const _peel = DamageMeasurement(type: DamageType.peelingPaint, quantity: 0.2);

void main() {
  test('Chưa có phiếu đánh giá: rỗng, chưa có điểm', () {
    final s = RepairCostSummary.fromRecords([
      record(1, code: 'A', assessed: false),
    ]);
    expect(s.isEmpty, isTrue);
    expect(s.facilityScore, isNull);
    expect(s.totalCost, 0);
  });

  test('Bỏ bản nháp; cùng mã lấy phiếu mới nhất', () {
    final s = RepairCostSummary.fromRecords([
      record(1, code: 'A', damages: [_water3]), // cũ: Nặng
      record(
        2,
        code: 'a',
        damages: [_water1],
      ), // mới: Vừa (mã không phân biệt hoa thường)
      record(3, code: 'B', damages: [_water3], signed: false), // nháp
    ]);
    expect(s.count, 1);
    expect(s.surfaces.single.record.id, 2);
    // 1 m² × 220.000 (Vừa, 10%)
    expect(s.totalCost, 220000);
    expect(s.facilityScore, closeTo(90, 1e-9));
  });

  test('Phiếu không có mã tính là bề mặt riêng', () {
    final s = RepairCostSummary.fromRecords([
      record(1, damages: [_water1]),
      record(2, damages: [_water1]),
    ]);
    expect(s.count, 2);
    expect(s.totalCost, 440000);
  });

  test('Xếp ưu tiên: nặng trước, rồi tiền nhiều trước', () {
    final s = RepairCostSummary.fromRecords([
      record(1, code: 'NHE', damages: [_peel]),
      record(2, code: 'NANG', damages: [_water3]),
      record(3, code: 'VUA', damages: [_water1]),
      record(4, code: 'TOT'),
    ]);
    expect(s.surfaces.map((e) => e.code), ['NANG', 'VUA', 'NHE', 'TOT']);
    expect(s.countWorst(DamageSeverity.severe), 1);
    expect(s.countWorst(DamageSeverity.light), 1);
  });

  test('Gom theo tòa nhà và phòng', () {
    final s = RepairCostSummary.fromRecords([
      record(1, code: '1', building: 'Nhà A', room: 'A101', damages: [_water1]),
      record(2, code: '2', building: 'Nhà A', room: 'A101', damages: [_peel]),
      record(3, code: '3', building: 'Nhà A', room: 'A102', damages: [_water3]),
      record(4, code: '4', building: 'Nhà B', room: 'B201'),
      record(5, code: '5', damages: [_peel]),
    ]);

    final buildings = s.byBuilding;
    expect(buildings.first.name, 'Nhà A');
    expect(buildings.first.surfaces, 3);
    expect(buildings.first.cost, 220000 + 0.2 * 60000 + 3 * 380000);
    expect(
      buildings.map((b) => b.name),
      containsAll(['Nhà B', RepairCostSummary.noBuilding]),
    );

    final rooms = s.byRoom;
    expect(rooms.first.name, 'A102'); // có hạng mục Nặng
    expect(rooms.first.building, 'Nhà A');
    final a101 = rooms.firstWhere((r) => r.name == 'A101');
    expect(a101.surfaces, 2);
    expect(a101.averageScore, closeTo((90 + 98) / 2, 1e-9));
    expect(rooms.firstWhere((r) => r.name == 'B201').worst, isNull);
  });

  test('Tiền theo loại hư hỏng và cờ giá minh hoạ', () {
    final s = RepairCostSummary.fromRecords([
      record(
        1,
        code: '1',
        damages: [
          _water1,
          const DamageMeasurement(type: DamageType.crack, quantity: 1),
        ],
      ),
    ]);
    expect(s.costByType[DamageType.waterMold], 220000);
    // 1 m / 10 m² = 0,1 m/m² => chỉ số 5 => Vừa: 150.000 đ/m
    expect(s.costByType[DamageType.crack], 150000);
    expect(s.usesSampleRates, isTrue);
    expect(s.unpricedItems, 0);
  });
}
