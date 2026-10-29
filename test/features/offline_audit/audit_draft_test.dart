import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AuditRecordModel record(int id, {List<int>? signature}) =>
      AuditRecordModel(id)
        ..scanCode = 'TS-$id'
        ..assetName = 'Tài sản $id'
        ..quantity = 1
        ..signatureBytes = signature
        ..timestamp = DateTime(2026, 10, 26);

  test('phiếu chưa có chữ ký (null hoặc rỗng) là bản nháp', () {
    expect(record(1).isDraft, isTrue);
    expect(record(2, signature: const []).isDraft, isTrue);
    expect(record(3, signature: [1, 2, 3]).isDraft, isFalse);
  });

  test('PDF báo cáo không gồm bản nháp', () async {
    final onlyDrafts = await PdfReportGenerator.generateAuditReport([
      record(1),
      record(2),
    ]);
    final empty = await PdfReportGenerator.generateAuditReport([]);
    // Toàn bản nháp cho ra đúng báo cáo rỗng.
    expect(onlyDrafts.length, empty.length);
  });

  test('provider tách phiếu chính thức và bản nháp', () {
    final container = ProviderContainer(
      overrides: [
        auditRecordsProvider.overrideWith(
          (ref) => Stream.value([
            record(1),
            record(2, signature: [1]),
            record(3, signature: [1])..isSynced = true,
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(auditRecordsProvider, (_, _) {});

    return Future<void>.delayed(Duration.zero, () {
      expect(container.read(draftAuditRecordsProvider).map((r) => r.id), [1]);
      expect(container.read(finalAuditRecordsProvider).map((r) => r.id), [
        2,
        3,
      ]);
      // Chỉ phiếu chính thức chưa đồng bộ mới tính là "chờ đồng bộ".
      expect(container.read(pendingSyncCountProvider), 1);
    });
  });

  test('copyWithId giữ mọi trường (gồm ảnh minh chứng) khi gán id mới', () {
    final original = AuditRecordModel(0, signatureBytes: [9, 9])
      ..scanCode = 'TS-1'
      ..aiDetectedLabel = 'Ghế'
      ..assetName = 'Ghế xoay'
      ..quantity = 4
      ..area = 'Kho'
      ..location = 'Kệ A3'
      ..condition = 'check'
      ..notes = 'ghi chú'
      ..signerName = 'Hoàng An'
      ..signerRole = 'Kiểm kê viên'
      ..photoFiles = ['a.jpg', 'b.jpg']
      ..timestamp = DateTime(2026, 10, 28, 9)
      ..isSynced = true;

    final copy = original.copyWithId(42);

    expect(copy.id, 42);
    expect(copy.scanCode, original.scanCode);
    expect(copy.aiDetectedLabel, original.aiDetectedLabel);
    expect(copy.assetName, original.assetName);
    expect(copy.quantity, original.quantity);
    expect(copy.area, original.area);
    expect(copy.location, original.location);
    expect(copy.condition, original.condition);
    expect(copy.notes, original.notes);
    expect(copy.signatureBytes, original.signatureBytes);
    expect(copy.signerName, original.signerName);
    expect(copy.signerRole, original.signerRole);
    expect(copy.photoFiles, ['a.jpg', 'b.jpg']);
    expect(copy.timestamp, original.timestamp);
    expect(copy.isSynced, isTrue);
  });
}
