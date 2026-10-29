import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/evidence_fakes.dart';

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

    test('PDF có nhãn kỳ báo cáo khác PDF không có nhãn', () async {
      final record = AuditRecordModel(1)
        ..scanCode = 'TS-DC-0142'
        ..quantity = 1
        ..signatureBytes = [1, 2, 3]
        ..timestamp = DateTime(2026, 10, 26);
      final plain = await PdfReportGenerator.generateAuditReport([record]);
      final labelled = await PdfReportGenerator.generateAuditReport([
        record,
      ], periodLabel: 'Tháng 10/2026');
      expect(ascii.decode(labelled.sublist(0, 5)), '%PDF-');
      expect(labelled.length, isNot(plain.length));
    });

    test('chữ ký hỏng không làm hỏng cả báo cáo', () async {
      final record = AuditRecordModel(1)
        ..scanCode = 'TS-DC-0142'
        ..quantity = 1
        ..signatureBytes = [1, 2, 3]
        ..timestamp = DateTime(2026, 10, 26);
      final bytes = await PdfReportGenerator.generateAuditReport([record]);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('PDF có ảnh minh chứng lớn hơn khi ảnh được cung cấp; thiếu ảnh vẫn tạo được', () async {
      final record = AuditRecordModel(1)
        ..scanCode = 'TS-DC-0142'
        ..quantity = 1
        ..signatureBytes = [1, 2, 3]
        ..photoFiles = ['a.jpg', 'missing.jpg']
        ..timestamp = DateTime(2026, 10, 26);

      final without = await PdfReportGenerator.generateAuditReport([record]);
      final withPhoto = await PdfReportGenerator.generateAuditReport(
        [record],
        photoBytes: {'a.jpg': sampleJpeg(size: 200)},
      );
      expect(ascii.decode(withPhoto.sublist(0, 5)), '%PDF-');
      expect(withPhoto.length, greaterThan(without.length));
    });

    test('ảnh minh chứng hỏng không làm hỏng báo cáo', () async {
      final record = AuditRecordModel(1)
        ..scanCode = 'TS-DC-0142'
        ..quantity = 1
        ..signatureBytes = [1, 2, 3]
        ..photoFiles = ['bad.jpg']
        ..timestamp = DateTime(2026, 10, 26);
      final bytes = await PdfReportGenerator.generateAuditReport(
        [record],
        photoBytes: {
          'bad.jpg': Uint8List.fromList([1, 2, 3]),
        },
      );
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
