import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/supabase_sync_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/sync_repository.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/screens/dashboard_screen.dart';

class MockAuditRepository implements AuditRepository {
  bool exportCalled = false;
  List<AuditRecordModel> records = [];

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
    exportCalled = true;
    return Uint8List.fromList([37, 80, 68, 70, 45]); // %PDF-
  }
}

class MockSyncRepository implements SyncRepository {
  bool syncCalled = false;

  @override
  Future<String?> uploadSignature(List<int> bytes) async => null;

  @override
  Future<void> syncPendingRecords(List<AuditRecordModel> records) async {
    syncCalled = true;
    for (final r in records) {
      r.isSynced = true;
    }
  }
}

void main() {
  group('DashboardScreen PDF & Cloud Sync Tests', () {
    late MockAuditRepository mockRepo;
    late MockSyncRepository mockSyncRepo;

    setUp(() {
      mockRepo = MockAuditRepository();
      mockSyncRepo = MockSyncRepository();
    });

    Widget createTestWidget({Size screenSize = const Size(400, 800)}) {
      return ProviderScope(
        overrides: [
          auditRepositoryProvider.overrideWithValue(mockRepo),
          isarAuditRepositoryProvider.overrideWithValue(mockRepo),
          syncRepositoryProvider.overrideWithValue(mockSyncRepo),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: const DashboardScreen(),
          ),
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

    testWidgets('Renders cloud sync button on Mobile and triggers sync', (
      tester,
    ) async {
      mockRepo.records = [
        AuditRecordModel(1)
          ..scanCode = 'QR-PENDING'
          ..quantity = 2
          ..isSynced = false,
      ];

      await tester.pumpWidget(createTestWidget(screenSize: const Size(400, 800)));
      await tester.pumpAndSettle();

      final syncBtn = find.byIcon(Icons.cloud_upload_outlined);
      expect(syncBtn, findsOneWidget);

      await tester.tap(syncBtn);
      await tester.pumpAndSettle();

      expect(mockSyncRepo.syncCalled, isTrue);
      expect(find.text('Đã đồng bộ thành công 1 bản ghi lên Supabase!'), findsOneWidget);
    });

    testWidgets('Renders sync button in Desktop Sidebar and triggers sync', (
      tester,
    ) async {
      mockRepo.records = [
        AuditRecordModel(1)
          ..scanCode = 'DESK-01'
          ..quantity = 10
          ..isSynced = false,
      ];

      await tester.pumpWidget(createTestWidget(screenSize: const Size(1200, 900)));
      await tester.pumpAndSettle();

      final sidebarSync = find.text('Đồng bộ Supabase');
      expect(sidebarSync, findsOneWidget);

      await tester.tap(sidebarSync);
      await tester.pumpAndSettle();

      expect(mockSyncRepo.syncCalled, isTrue);
      expect(find.text('Đã đồng bộ thành công 1 bản ghi lên Supabase!'), findsOneWidget);
    });
  });
}

