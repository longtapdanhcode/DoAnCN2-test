import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/entities/asset_status.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/screens/asset_editor_screen.dart';

/// Danh mục trong bộ nhớ, đếm số lần lưu và đồng bộ.
class _MemoryCatalog implements AssetCatalogRepository {
  _MemoryCatalog([List<AssetModel> initial = const []])
    : items = {for (final a in initial) a.code: a};

  final Map<String, AssetModel> items;
  int syncCalls = 0;

  @override
  Stream<List<AssetModel>> watchAll() => Stream.value(items.values.toList());

  @override
  Future<AssetModel?> findByCode(String code) async => items[code];

  @override
  Future<void> save(AssetModel asset) async {
    items[asset.code] = asset..isSynced = false;
  }

  @override
  Future<CatalogSyncResult> sync() async {
    syncCalls++;
    for (final a in items.values) {
      a.isSynced = true;
    }
    return CatalogSyncResult(pushed: 1, pulled: items.length);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _MemoryCatalog catalog, {
  String? code,
  bool online = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/editor',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Text('home')),
      GoRoute(
        path: '/assets',
        builder: (context, state) => const Text('assets list'),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) =>
            Scaffold(body: AssetEditorScreen(code: code)),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetCatalogRepositoryProvider.overrideWithValue(catalog),
        isOnlineProvider.overrideWith((ref) => Stream.value(online)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextFormField),
);

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.text('Lưu tài sản');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Adds a new asset, uppercases the code and syncs when online', (
    tester,
  ) async {
    final catalog = _MemoryCatalog();
    await _pump(tester, catalog);

    await tester.enterText(_field('Mã tài sản *'), 'ts-new-0001');
    await tester.enterText(_field('Tên tài sản *'), 'Máy nén khí Atlas');
    await tester.enterText(_field('Khu vực'), 'Kho trung tâm');
    await tester.enterText(_field('Số lượng *'), '3');
    await tester.ensureVisible(find.text('Hư hỏng'));
    await tester.tap(find.text('Hư hỏng'));
    await _tapSave(tester);

    final saved = catalog.items['TS-NEW-0001'];
    expect(saved, isNotNull);
    expect(saved!.name, 'Máy nén khí Atlas');
    expect(saved.area, 'Kho trung tâm');
    expect(saved.location, isNull);
    expect(saved.quantity, 3);
    expect(saved.assetStatus, AssetStatus.damaged);
    expect(catalog.syncCalls, 1);
    expect(find.text('assets list'), findsOneWidget);
  });

  testWidgets('Offline: saves on device without syncing', (tester) async {
    final catalog = _MemoryCatalog();
    await _pump(tester, catalog, online: false);

    await tester.enterText(_field('Mã tài sản *'), 'TS-OFF-1');
    await tester.enterText(_field('Tên tài sản *'), 'Tủ lạnh mẫu');
    await _tapSave(tester);

    expect(catalog.items['TS-OFF-1'], isNotNull);
    expect(catalog.items['TS-OFF-1']!.isSynced, isFalse);
    expect(catalog.syncCalls, 0);
  });

  testWidgets('Rejects a code that already exists', (tester) async {
    final catalog = _MemoryCatalog([
      AssetModel('TS-DC-0142')..name = 'Động cơ',
    ]);
    await _pump(tester, catalog);

    await tester.enterText(_field('Mã tài sản *'), 'ts-dc-0142');
    await tester.enterText(_field('Tên tài sản *'), 'Trùng mã');
    await _tapSave(tester);

    expect(catalog.items['TS-DC-0142']!.name, 'Động cơ');
    expect(find.textContaining('đã có trong danh mục'), findsOneWidget);
  });

  testWidgets('Requires code and name', (tester) async {
    final catalog = _MemoryCatalog();
    await _pump(tester, catalog);

    await _tapSave(tester);

    expect(find.text('Vui lòng nhập mã tài sản'), findsOneWidget);
    expect(find.text('Vui lòng nhập tên tài sản'), findsOneWidget);
    expect(catalog.items, isEmpty);
  });

  testWidgets('Edits an existing asset; the code cannot be changed', (
    tester,
  ) async {
    final catalog = _MemoryCatalog([
      AssetModel('TS-BOM-0248')
        ..name = 'Máy bơm ly tâm Ebara'
        ..quantity = 12
        ..lastAuditAt = DateTime(2026, 10, 22),
    ]);
    await _pump(tester, catalog, code: 'TS-BOM-0248');

    expect(find.text('Sửa tài sản'), findsOneWidget);
    final codeField = tester.widget<TextFormField>(_field('Mã tài sản *'));
    expect(codeField.enabled, isFalse);

    await tester.enterText(_field('Số lượng *'), '10');
    await _tapSave(tester);

    final saved = catalog.items['TS-BOM-0248']!;
    expect(saved.quantity, 10);
    expect(saved.name, 'Máy bơm ly tâm Ebara');
    // Lần kiểm kê gần nhất không bị mất khi sửa.
    expect(saved.lastAuditAt, DateTime(2026, 10, 22));
  });
}
