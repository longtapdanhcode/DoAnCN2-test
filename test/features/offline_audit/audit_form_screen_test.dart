import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/screens/audit_form_screen.dart';

class MockAuditRepository implements AuditRepository {
  final List<AuditRecordModel> records = [];

  @override
  Future<void> saveRecord(AuditRecordModel record) async {
    records.add(record);
  }

  @override
  Future<List<AuditRecordModel>> getAllRecords() async {
    return records;
  }

  @override
  Future<Uint8List> exportPdfReport() async {
    return Uint8List(0);
  }
}

/// Kích thước khung web 1440×1000 của Figma (bố cục desktop).
void useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('AuditFormScreen Widget Tests', () {
    late MockAuditRepository mockRepo;

    setUp(() {
      mockRepo = MockAuditRepository();
    });

    Widget createTestWidget({required String scanCode, String? aiLabel}) {
      final router = GoRouter(
        initialLocation: '/audit-form',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: '/audit-form',
            // Trong app, khung FieldlineShell cung cấp Scaffold.
            builder: (context, state) => Scaffold(
              body: AuditFormScreen(
                initialScanCode: scanCode,
                initialAiLabel: aiLabel,
              ),
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [isarAuditRepositoryProvider.overrideWithValue(mockRepo)],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('Renders scan code, AI label, and default quantity 1', (
      tester,
    ) async {
      useDesktopView(tester);
      await tester.pumpWidget(
        createTestWidget(
          scanCode: 'DEVICE-ABC-999',
          aiLabel: 'Laptop ThinkPad',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lập phiếu kiểm kê'), findsOneWidget);
      expect(find.text('DEVICE-ABC-999'), findsOneWidget);
      // Nhãn AI điền sẵn cả "Loại thiết bị" và "Tên tài sản".
      expect(find.text('Laptop ThinkPad'), findsNWidgets(2));
      expect(find.text('01'), findsOneWidget);
      expect(find.text('Tiếp tục ký xác nhận'), findsOneWidget);
    });

    testWidgets('Quick add buttons increment quantity', (tester) async {
      useDesktopView(tester);
      await tester.pumpWidget(
        createTestWidget(scanCode: 'DEVICE-ABC-999', aiLabel: 'Server Rack'),
      );
      await tester.pumpAndSettle();

      // Scroll to +5 button and tap
      final plus5Finder = find.widgetWithText(OutlinedButton, '+5');
      await tester.ensureVisible(plus5Finder);
      await tester.tap(plus5Finder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('06'), findsOneWidget);

      // Scroll to +10 button and tap
      final plus10Finder = find.widgetWithText(OutlinedButton, '+10');
      await tester.ensureVisible(plus10Finder);
      await tester.tap(plus10Finder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('16'), findsOneWidget);
    });

    testWidgets('Submitting form saves record to repository', (tester) async {
      useDesktopView(tester);
      await tester.pumpWidget(
        createTestWidget(
          scanCode: 'DEVICE-TEST-001',
          aiLabel: 'Monitor 27-inch',
        ),
      );
      await tester.pumpAndSettle();

      // Nhập khu vực, chọn tình trạng và ghi chú trước khi lưu
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ví dụ: Xưởng sản xuất A'),
        'Kho trung tâm',
      );
      await tester.tap(find.text('Cần kiểm tra'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bổ sung hiện trạng hoặc sai lệch…'),
        'Màn hình bị sọc',
      );
      await tester.pumpAndSettle();

      // "Lưu bản nháp" lưu phiếu ngay, không cần chữ ký
      final submitFinder = find.text('Lưu bản nháp');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(mockRepo.records.length, 1);
      final record = mockRepo.records.first;
      expect(record.scanCode, 'DEVICE-TEST-001');
      expect(record.aiDetectedLabel, 'Monitor 27-inch');
      expect(record.quantity, 1);
      expect(record.area, 'Kho trung tâm');
      expect(record.location, isNull);
      expect(record.condition, 'check');
      expect(record.notes, 'Màn hình bị sọc');
      // Tên tài sản được điền sẵn từ nhãn AI và lưu cùng phiếu.
      expect(record.assetName, 'Monitor 27-inch');
      expect(record.signerName, isNull);
    });

    testWidgets('mở lại bản nháp: điền sẵn dữ liệu đã lưu', (tester) async {
      // Màn mobile đủ cao để danh sách dựng hết các trường.
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final draft = AuditRecordModel(5)
        ..scanCode = 'TS-MK-0321'
        ..aiDetectedLabel = 'Máy khoan'
        ..assetName = 'Máy khoan Bosch GSB'
        ..area = 'Kho trung tâm'
        ..location = 'Kệ A3'
        ..notes = 'Cần kiểm tra lại dây nguồn'
        ..quantity = 4
        ..condition = 'check'
        ..timestamp = DateTime(2026, 10, 26, 9, 30);

      final router = GoRouter(
        initialLocation: '/audit-form',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: '/audit-form',
            builder: (context, state) => const Scaffold(
              body: AuditFormScreen(initialScanCode: '', draftId: 5),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isarAuditRepositoryProvider.overrideWithValue(mockRepo),
            auditRecordsProvider.overrideWith((ref) => Stream.value([draft])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TS-MK-0321'), findsWidgets);
      expect(find.text('Máy khoan Bosch GSB'), findsWidgets);
      expect(find.text('Kho trung tâm'), findsWidgets);
      expect(find.text('04'), findsWidgets);
    });
  });
}
