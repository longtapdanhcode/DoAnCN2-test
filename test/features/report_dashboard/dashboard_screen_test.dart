import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/screens/dashboard_screen.dart';

class MockAuditRepository implements AuditRepository {
  bool exportCalled = false;

  @override
  Future<void> saveRecord(AuditRecordModel record) async {}

  @override
  Future<List<AuditRecordModel>> getAllRecords() async {
    return [];
  }

  @override
  Future<Uint8List> exportPdfReport() async {
    exportCalled = true;
    return Uint8List.fromList([37, 80, 68, 70, 45]); // %PDF-
  }
}

void main() {
  group('DashboardScreen PDF Export Tests', () {
    late MockAuditRepository mockRepo;

    setUp(() {
      mockRepo = MockAuditRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          auditRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Renders PDF export actions on AppBar and Dashboard body', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNWidgets(2));
      expect(find.text('Xuất Báo cáo PDF'), findsOneWidget);
    });
  });
}
