import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
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

void main() {
  group('AuditFormScreen Widget Tests', () {
    late MockAuditRepository mockRepo;

    setUp(() {
      mockRepo = MockAuditRepository();
    });

    Widget createTestWidget({
      required String scanCode,
      String? aiLabel,
    }) {
      final router = GoRouter(
        initialLocation: '/audit-form',
        routes: [
          GoRoute(
            path: '/audit-form',
            builder: (context, state) => AuditFormScreen(
              initialScanCode: scanCode,
              initialAiLabel: aiLabel,
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Renders scan code, AI label, and default quantity 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          scanCode: 'DEVICE-ABC-999',
          aiLabel: 'Laptop ThinkPad',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biểu mẫu kiểm kê'), findsOneWidget);
      expect(find.text('DEVICE-ABC-999'), findsOneWidget);
      expect(find.text('Laptop ThinkPad'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Lưu kiểm kê'), findsOneWidget);
    });

    testWidgets('Quick adjust chips increment quantity', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          scanCode: 'DEVICE-ABC-999',
          aiLabel: 'Server Rack',
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to +5 chip and tap
      final plus5Finder = find.widgetWithText(ActionChip, '+5');
      await tester.ensureVisible(plus5Finder);
      await tester.tap(plus5Finder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('6'), findsOneWidget);

      // Scroll to +10 chip and tap
      final plus10Finder = find.widgetWithText(ActionChip, '+10');
      await tester.ensureVisible(plus10Finder);
      await tester.tap(plus10Finder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('16'), findsOneWidget);
    });

    testWidgets('Submitting form saves record to repository', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          scanCode: 'DEVICE-TEST-001',
          aiLabel: 'Monitor 27-inch',
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to 'Lưu kiểm kê' and tap
      final submitFinder = find.text('Lưu kiểm kê');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(mockRepo.records.length, 1);
      final record = mockRepo.records.first;
      expect(record.scanCode, 'DEVICE-TEST-001');
      expect(record.aiDetectedLabel, 'Monitor 27-inch');
      expect(record.quantity, 1);
    });
  });
}
