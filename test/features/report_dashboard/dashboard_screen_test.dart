import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/supabase_sync_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/sync_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/screens/sync_screen.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/screens/dashboard_screen.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/screens/reports_screen.dart';

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

class FakeAssetCatalogRepository implements AssetCatalogRepository {
  int syncCalls = 0;

  @override
  Stream<List<AssetModel>> watchAll() => Stream.value(const []);

  @override
  Future<AssetModel?> findByCode(String code) async => null;

  @override
  Future<void> save(AssetModel asset) async {}

  @override
  Future<CatalogSyncResult> sync() async {
    syncCalls++;
    return const CatalogSyncResult(pushed: 0, pulled: 3);
  }
}

void main() {
  group('Dashboard, PDF & Cloud Sync Tests', () {
    late MockAuditRepository mockRepo;
    late MockSyncRepository mockSyncRepo;
    late FakeAssetCatalogRepository catalogRepo;

    setUp(() {
      mockRepo = MockAuditRepository();
      mockSyncRepo = MockSyncRepository();
      catalogRepo = FakeAssetCatalogRepository();
    });

    Future<void> pumpScreen(
      WidgetTester tester,
      Widget screen, {
      Size screenSize = const Size(400, 800),
      bool online = true,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditRepositoryProvider.overrideWithValue(mockRepo),
            isarAuditRepositoryProvider.overrideWithValue(mockRepo),
            syncRepositoryProvider.overrideWithValue(mockSyncRepo),
            auditRecordsProvider.overrideWith(
              (ref) => Stream.value(mockRepo.records),
            ),
            isOnlineProvider.overrideWith((ref) => Stream.value(online)),
            assetCatalogRepositoryProvider.overrideWithValue(catalogRepo),
          ],
          child: MaterialApp(home: Scaffold(body: screen)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Mobile dashboard shows pending records', (tester) async {
      mockRepo.records = [
        AuditRecordModel(1)
          ..scanCode = 'QR-PENDING'
          ..quantity = 2
          ..timestamp = DateTime.now()
          ..signatureBytes = [1, 2, 3]
          ..isSynced = false,
      ];

      await pumpScreen(tester, const DashboardScreen());

      expect(find.text('Tổng quan'), findsOneWidget);
      expect(
        find.text('1 phiếu chờ đồng bộ • lưu trên thiết bị'),
        findsOneWidget,
      );
      expect(find.text('Quét thiết bị'), findsOneWidget);
    });

    testWidgets('Desktop dashboard lists recent audit records', (tester) async {
      mockRepo.records = [
        AuditRecordModel(7)
          ..scanCode = 'DESK-01'
          ..aiDetectedLabel = 'Động cơ điện'
          ..quantity = 10
          ..timestamp = DateTime(2026, 10, 22)
          ..signatureBytes = [1, 2, 3]
          ..isSynced = false,
      ];

      await pumpScreen(
        tester,
        const DashboardScreen(),
        screenSize: const Size(1440, 1000),
      );

      expect(find.text('Tổng quan hiện trường'), findsOneWidget);
      expect(find.text('KK-2026-007'), findsOneWidget);
      expect(find.text('Chờ đồng bộ'), findsWidgets);
    });

    testWidgets('Sync screen "Đồng bộ ngay" triggers sync', (tester) async {
      mockRepo.records = [
        AuditRecordModel(1)
          ..scanCode = 'DESK-01'
          ..quantity = 10
          ..signatureBytes = [1, 2, 3]
          ..isSynced = false,
      ];

      await pumpScreen(
        tester,
        const SyncScreen(),
        screenSize: const Size(1440, 1000),
      );

      await tester.tap(find.text('Đồng bộ ngay'));
      await tester.pumpAndSettle();

      expect(mockSyncRepo.syncCalled, isTrue);
      expect(catalogRepo.syncCalls, 1);
      expect(
        find.text('Đã đồng bộ 1 phiếu lên đám mây. Danh mục: 3 tài sản.'),
        findsOneWidget,
      );
    });

    testWidgets('Offline: sync is skipped and user is told why', (
      tester,
    ) async {
      mockRepo.records = [
        AuditRecordModel(1)
          ..scanCode = 'OFF-01'
          ..quantity = 1
          ..signatureBytes = [1, 2, 3]
          ..isSynced = false,
      ];

      await pumpScreen(
        tester,
        const SyncScreen(),
        screenSize: const Size(1440, 1000),
        online: false,
      );

      expect(
        find.textContaining('Thiết bị đang ngoại tuyến • 1 phiếu'),
        findsOneWidget,
      );

      await tester.tap(find.text('Đồng bộ ngay'));
      await tester.pumpAndSettle();

      expect(mockSyncRepo.syncCalled, isFalse);
      expect(catalogRepo.syncCalls, 0);
      expect(
        find.text(
          'Thiết bị đang ngoại tuyến. Phiếu vẫn được lưu trên máy và sẽ đồng bộ khi có mạng.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Reports screen exports PDF', (tester) async {
      await pumpScreen(
        tester,
        const ReportsScreen(),
        screenSize: const Size(1440, 1000),
      );

      await tester.tap(find.text('Xuất báo cáo PDF'));
      await tester.pump();

      // Xuất theo kỳ đang chọn: báo đang tạo PDF (hộp chia sẻ không có trong test).
      expect(find.text('Đang tạo báo cáo PDF...'), findsOneWidget);
    });
  });
}
