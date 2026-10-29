import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/supabase_sync_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/sync_repository.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/entities/asset_status.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/screens/assets_screen.dart';

class _EmptyAuditRepository implements AuditRepository {
  @override
  Future<void> deleteRecord(int id) async {}

  @override
  Future<void> saveRecord(AuditRecordModel record) async {}

  @override
  Future<List<AuditRecordModel>> getAllRecords() async => [];

  @override
  Future<Uint8List> exportPdfReport() async => Uint8List(0);
}

class _NoopSyncRepository implements SyncRepository {
  @override
  Future<String> uploadEvidencePhoto(List<int> bytes) async =>
      'https://example.test/evidence.jpg';

  @override
  Future<void> syncPendingRecords(List<AuditRecordModel> records) async {}

  @override
  Future<String?> uploadSignature(List<int> bytes) async => null;
}

class _FakeCatalogRepository implements AssetCatalogRepository {
  @override
  Future<void> resolveConflict(
    String code,
    Set<String> useRemoteFields,
  ) async {}

  int syncCalls = 0;

  @override
  Stream<List<AssetModel>> watchAll() => Stream.value(const []);

  @override
  Future<AssetModel?> findByCode(String code) async => null;

  @override
  Future<void> save(AssetModel asset) async {}

  @override
  Future<CatalogSyncResult> sync() async {
    // Khoảng chờ bất đồng bộ như khi gọi mạng thật.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    syncCalls++;
    return const CatalogSyncResult(pushed: 0, pulled: 0);
  }
}

List<AssetModel> _catalog() => [
  AssetModel('TS-BOM-0248')
    ..name = 'Máy bơm ly tâm Ebara'
    ..area = 'Kho trung tâm'
    ..status = AssetStatus.good.code
    ..lastAuditAt = DateTime(2026, 10, 22),
  AssetModel('TS-DC-0142')
    ..name = 'Động cơ điện Siemens'
    ..area = 'Xưởng sản xuất A'
    ..status = AssetStatus.check.code,
  AssetModel('TS-VAN-0175')
    ..name = 'Van công nghiệp DN100'
    ..area = 'Kho trung tâm'
    ..status = AssetStatus.damaged.code
    ..lastAuditAt = DateTime(2026, 10, 20),
];

Future<void> _pump(
  WidgetTester tester,
  List<AssetModel> assets, {
  Size size = const Size(1440, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [assetsProvider.overrideWith((ref) => Stream.value(assets))],
      child: const MaterialApp(home: Scaffold(body: AssetsScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Desktop shows real catalog stats and rows', (tester) async {
    await _pump(tester, _catalog());

    expect(find.text('Máy bơm ly tâm Ebara'), findsOneWidget);
    expect(find.text('Động cơ điện Siemens'), findsOneWidget);
    expect(find.text('Cần kiểm tra 2'), findsOneWidget);
    expect(find.text('Chưa kiểm kê 1'), findsOneWidget);
    expect(find.text('Hiển thị 3 trong 3 tài sản'), findsOneWidget);
  });

  testWidgets('"Cần kiểm tra" tab keeps only check and damaged assets', (
    tester,
  ) async {
    await _pump(tester, _catalog());

    await tester.tap(find.text('Cần kiểm tra 2'));
    await tester.pumpAndSettle();

    expect(find.text('Máy bơm ly tâm Ebara'), findsNothing);
    expect(find.text('Động cơ điện Siemens'), findsOneWidget);
    expect(find.text('Van công nghiệp DN100'), findsOneWidget);
  });

  testWidgets('Search filters by code', (tester) async {
    await _pump(tester, _catalog());

    await tester.enterText(find.byType(TextField).first, 'van-0175');
    await tester.pumpAndSettle();

    expect(find.text('Van công nghiệp DN100'), findsOneWidget);
    expect(find.text('Máy bơm ly tâm Ebara'), findsNothing);
  });

  testWidgets('Empty catalog offers to sync', (tester) async {
    await _pump(tester, const [], size: const Size(390, 844));

    expect(find.text('Chưa có tài sản nào trên máy.'), findsOneWidget);
    expect(find.text('Đồng bộ danh mục'), findsOneWidget);
  });

  testWidgets(
    'Syncing from the assets screen works without anyone watching the sync controller',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final catalog = _FakeCatalogRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetsProvider.overrideWith((ref) => Stream.value(const [])),
            assetCatalogRepositoryProvider.overrideWithValue(catalog),
            isarAuditRepositoryProvider.overrideWithValue(
              _EmptyAuditRepository(),
            ),
            syncRepositoryProvider.overrideWithValue(_NoopSyncRepository()),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: const MaterialApp(home: Scaffold(body: AssetsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đồng bộ danh mục'));
      await tester.pumpAndSettle();

      expect(catalog.syncCalls, 1);
      expect(
        find.text('Không có phiếu nào cần đồng bộ. Danh mục: 0 tài sản.'),
        findsOneWidget,
      );
    },
  );
}
