import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Asset list PDF is generated with Vietnamese text', () async {
    final bytes = await PdfReportGenerator.generateAssetList([
      AssetModel('TS-DC-0142')
        ..name = 'Động cơ điện Siemens'
        ..area = 'Xưởng sản xuất A'
        ..quantity = 8
        ..status = 'check',
      AssetModel('TS-VAN-0175')
        ..name = 'Van công nghiệp DN100'
        ..quantity = 36
        ..status = 'damaged'
        ..lastAuditAt = DateTime(2026, 10, 20),
    ]);

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // Font Inter được nhúng (không rơi về Helvetica không có dấu).
    expect(String.fromCharCodes(bytes), contains('Inter'));
  });

  test('Empty asset list still produces a PDF', () async {
    final bytes = await PdfReportGenerator.generateAssetList(const []);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
