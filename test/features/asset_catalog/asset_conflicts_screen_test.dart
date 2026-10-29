import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/asset_merge.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/screens/asset_conflicts_screen.dart';

class _Repo implements AssetCatalogRepository {
  String? resolvedCode;
  Set<String>? resolvedFields;

  @override
  Future<void> resolveConflict(String code, Set<String> useRemoteFields) async {
    resolvedCode = code;
    resolvedFields = useRemoteFields;
  }

  @override
  Stream<List<AssetModel>> watchAll() => Stream.value(const []);

  @override
  Future<AssetModel?> findByCode(String code) async => null;

  @override
  Future<void> save(AssetModel asset) async {}

  @override
  Future<CatalogSyncResult> sync() async =>
      const CatalogSyncResult(pushed: 0, pulled: 0);
}

AssetModel _conflicted() {
  final base = AssetModel('TS-01')
    ..name = 'Tủ điện'
    ..quantity = 1
    ..updatedAt = DateTime.utc(2026, 10, 20);
  final remote = AssetModel.fromJson(base.toJson())
    ..quantity = 7
    ..area = 'Kho B'
    ..updatedAt = DateTime.utc(2026, 10, 26);
  return AssetModel.fromJson(base.toJson())
    ..quantity = 4
    ..area = 'Xưởng A'
    ..isSynced = false
    ..updatedAt = DateTime.utc(2026, 10, 27)
    ..baseJson = jsonEncode(assetContent(base))
    ..conflictJson = jsonEncode(remote.toJson());
}

void main() {
  late _Repo repo;

  Future<void> pump(WidgetTester tester, List<AssetModel> assets) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetCatalogRepositoryProvider.overrideWithValue(repo),
          assetsProvider.overrideWith((ref) => Stream.value(assets)),
          isOnlineProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: const MaterialApp(home: Scaffold(body: AssetConflictsScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Hiện các mục khác nhau và lưu lựa chọn theo từng mục', (
    tester,
  ) async {
    await pump(tester, [_conflicted()]);

    expect(find.text('1 tài sản khác phiên bản'), findsOneWidget);
    expect(find.text('Số lượng'), findsOneWidget);
    expect(find.text('Khu vực'), findsOneWidget);
    expect(find.text('Tên tài sản'), findsNothing); // hai bên giống nhau

    await tester.tap(find.text('7'));
    await tester.pump();
    await tester.tap(find.text('Lưu lựa chọn'));
    await tester.pumpAndSettle();

    expect(repo.resolvedCode, 'TS-01');
    expect(repo.resolvedFields, {'quantity'});
    expect(find.textContaining('Đã đối chiếu TS-01'), findsOneWidget);
  });

  testWidgets('Lấy bản đám mây chọn mọi mục của máy chủ', (tester) async {
    await pump(tester, [_conflicted()]);

    await tester.tap(find.text('Lấy bản đám mây'));
    await tester.pumpAndSettle();

    expect(repo.resolvedFields, {...assetFieldLabels.keys});
  });

  testWidgets('Không có xung đột thì báo đã khớp', (tester) async {
    await pump(tester, const []);
    expect(find.text('Không còn tài sản nào cần đối chiếu'), findsOneWidget);
  });
}
