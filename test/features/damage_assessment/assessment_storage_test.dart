import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/asset_merge.dart';
import 'package:field_inventory_edge_ai/features/cloud_console/data/cloud_console_data.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/data/sample_repair_rates.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_calculator.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/repair_rate.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/surface_assessment.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/cloud_audit_record_model.dart';

void main() {
  final assessment =
      const DamageCalculator(
        RepairRateTable(sampleRepairRates, source: RepairRateSource.sample),
      ).assess(
        material: SurfaceMaterial.paintedWall,
        surfaceAreaM2: 10,
        measurements: const [
          DamageMeasurement(type: DamageType.waterMold, quantity: 1),
          DamageMeasurement(type: DamageType.crack, quantity: 0.6),
        ],
      );

  group('Phiếu kiểm kê lưu đánh giá hư hỏng', () {
    test('applyAssessment ghi JSON, tổng tiền và chỉ số', () {
      final record = AuditRecordModel(1)..applyAssessment(assessment);
      expect(record.estimatedCost, assessment.totalCost);
      expect(record.damageIndex, assessment.damageIndex);
      expect(record.surfaceAssessment, assessment);

      record.applyAssessment(null);
      expect(record.damageAssessmentJson, isNull);
      expect(record.estimatedCost, isNull);
      expect(record.surfaceAssessment, isNull);
    });

    test('copyWithId giữ đánh giá', () {
      final copy = (AuditRecordModel(
        1,
      )..applyAssessment(assessment)).copyWithId(7);
      expect(copy.surfaceAssessment, assessment);
      expect(copy.estimatedCost, assessment.totalCost);
    });

    test('Đồng bộ lên cloud rồi đọc lại ở bản web không mất dữ liệu', () {
      final record = AuditRecordModel(1)
        ..scanCode = 'P-A101'
        ..timestamp = DateTime.utc(2026, 11, 12)
        ..applyAssessment(assessment);
      final cloud = CloudAuditRecordModel.fromAuditRecordModel(
        record,
        id: 'id-1',
      );
      final json = cloud.toJson();
      expect(json['estimated_cost'], assessment.totalCost);
      expect(json['damage_index'], assessment.damageIndex);
      expect(json['damage_assessment'], isA<Map<String, dynamic>>());
      expect(CloudAuditRecordModel.fromJson(json), cloud);

      final web = cloudRowsToRecords([json]).single;
      expect(web.surfaceAssessment, assessment);
      expect(web.estimatedCost, assessment.totalCost);
    });

    test('Phiếu không đánh giá không gửi cột mới (bảng cũ vẫn nhận)', () {
      final json = CloudAuditRecordModel.fromAuditRecordModel(
        AuditRecordModel(1)..scanCode = 'X',
        id: 'id-2',
      ).toJson();
      expect(json.containsKey('damage_assessment'), isFalse);
      expect(json.containsKey('estimated_cost'), isFalse);
      expect(json.containsKey('damage_index'), isFalse);
    });
  });

  group('Tài sản có diện tích bề mặt', () {
    test('toJson/fromJson giữ diện tích; không có thì không gửi', () {
      final a = AssetModel('P-A101-TT')
        ..name = 'Tường trái'
        ..surfaceAreaM2 = 18.5;
      expect(a.toJson()['surface_area_m2'], 18.5);
      expect(AssetModel.fromJson(a.toJson()).surfaceAreaM2, 18.5);
      expect(AssetModel('X').toJson().containsKey('surface_area_m2'), isFalse);
    });

    test('Đối chiếu ba chiều nhận ra hai bên cùng sửa diện tích', () {
      final base = assetContent(AssetModel('A')..surfaceAreaM2 = 10);
      final local = assetContent(AssetModel('A')..surfaceAreaM2 = 12);
      final remote = assetContent(AssetModel('A')..surfaceAreaM2 = 14);
      expect(mergeAsset(base: base, local: local, remote: remote).conflicts, [
        'surface_area_m2',
      ]);
      // Chỉ máy chủ sửa: lấy bản máy chủ.
      final merged = mergeAsset(base: base, local: base, remote: remote);
      expect(merged.conflicts, isEmpty);
      expect(merged.merged['surface_area_m2'], 14);
    });
  });
}
