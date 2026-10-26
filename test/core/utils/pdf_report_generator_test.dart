import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReportGenerator Tests', () {
    test(
      'generateAuditReport produces valid PDF bytes for empty records list',
      () async {
        final bytes = await PdfReportGenerator.generateAuditReport([]);

        expect(bytes, isNotEmpty);
        // Valid PDF document starts with '%PDF-'
        final header = ascii.decode(bytes.sublist(0, 5));
        expect(header, '%PDF-');
      },
    );

    test('generateAuditReport produces valid PDF bytes with populated audit records', () async {
      final records = [
        AuditRecordModel(1)
          ..scanCode = 'INV-DEV-001'
          ..aiDetectedLabel = 'Laptop Dell XPS'
          ..quantity = 2
          ..timestamp = DateTime.utc(2026, 10, 9, 10, 30),
        AuditRecordModel(2)
          ..scanCode = 'INV-DEV-002'
          ..aiDetectedLabel = 'Màn hình Dell UltraSharp'
          ..quantity = 5
          ..timestamp = DateTime.utc(2026, 10, 9, 11, 15),
      ];

      final bytes = await PdfReportGenerator.generateAuditReport(records);

      expect(bytes, isNotEmpty);
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');
      // Ensure generated PDF size is reasonable
      expect(bytes.length, greaterThan(1000));
    });

    test('PDF có chữ ký lớn hơn PDF cùng nội dung không có chữ ký', () async {
      final signature = img.Image(width: 200, height: 80, numChannels: 4);
      img.fill(signature, color: img.ColorRgba8(0, 0, 0, 0));
      for (var x = 10; x < 190; x++) {
        img.fillCircle(
          signature,
          x: x,
          y: 40 + (x % 20),
          radius: 2,
          color: img.ColorRgba8(20, 30, 120, 255),
        );
      }

      AuditRecordModel record({List<int>? signatureBytes}) =>
          AuditRecordModel(1)
            ..scanCode = 'TS-DC-0142'
            ..assetName = 'Động cơ điện'
            ..quantity = 1
            ..condition = 'good'
            ..signerName = 'Hoàng An'
            ..signatureBytes = signatureBytes
            ..timestamp = DateTime(2026, 10, 26);

      final withSignature = await PdfReportGenerator.generateAuditReport([
        record(signatureBytes: img.encodePng(signature)),
      ]);
      final without = await PdfReportGenerator.generateAuditReport([record()]);

      expect(ascii.decode(withSignature.sublist(0, 5)), '%PDF-');
      expect(withSignature.length, greaterThan(without.length));
    });
  });
}
