import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/data/sample_repair_rates.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_calculator.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/repair_rate.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/surface_assessment.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Biên bản PDF có phiếu đánh giá hư hỏng vẫn xuất được', () async {
    const calc = DamageCalculator(
      RepairRateTable(sampleRepairRates, source: RepairRateSource.sample),
    );
    final records = [
      for (var i = 0; i < 40; i++)
        AuditRecordModel(i + 1, signatureBytes: Uint8List(0))
          ..scanCode = 'P-$i'
          ..assetName = 'Tường $i'
          ..area = 'Nhà ${String.fromCharCode(65 + i % 3)}'
          ..location = 'Phòng ${100 + i}'
          ..signatureUrl = 'cloud:$i'
          ..timestamp = DateTime(2026, 11, 1 + i % 28)
          ..applyAssessment(
            calc.assess(
              material: SurfaceMaterial.paintedWall,
              surfaceAreaM2: 12,
              measurements: [
                DamageMeasurement(type: DamageType.waterMold, quantity: i / 10),
                const DamageMeasurement(type: DamageType.crack, quantity: 0.8),
              ],
            ),
          ),
    ];
    final bytes = await PdfReportGenerator.generateAuditReport(
      records,
      periodLabel: 'Tháng 11/2026',
    );
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
