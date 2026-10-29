import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/platform/app_mode.dart';
import 'package:field_inventory_edge_ai/core/router/app_router.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/features/cloud_console/data/cloud_console_data.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/main.dart';

import '../../helpers/auth_fakes.dart';

class _Remote implements AssetRemoteDataSource {
  final rows = <Map<String, dynamic>>[
    {'code': 'TS-02', 'name': 'Tủ điện', 'quantity': 1},
    {'code': 'TS-01', 'name': 'Bàn', 'quantity': 4},
  ];
  final upserted = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => [...rows];

  @override
  Future<void> upsert(List<Map<String, dynamic>> r) async {
    upserted.addAll(r);
    for (final row in r) {
      rows.removeWhere((e) => e['code'] == row['code']);
      rows.add(row);
    }
  }
}

void main() {
  group('cloudRowsToRecords', () {
    test('phiếu trên đám mây là phiếu đã ký, mới nhất trước, đánh số theo thời gian', () {
      final records = cloudRowsToRecords([
        {
          'id': 'b',
          'scan_code': 'TS-02',
          'quantity': 2,
          'timestamp': '2026-10-28T02:00:00Z',
          'signature_url': 'https://x.test/sig.png',
          'photo_urls': ['https://x.test/p1.jpg'],
          'signer_name': 'Hoàng An',
        },
        {
          'id': 'a',
          'scan_code': 'TS-01',
          'quantity': 1,
          'timestamp': '2026-10-27T02:00:00Z',
        },
      ]);

      expect(records.map((r) => r.scanCode), ['TS-02', 'TS-01']);
      expect(records.map((r) => r.id), [2, 1]);
      expect(records.every((r) => !r.isDraft && r.isSynced), isTrue);
      expect(records.first.signatureUrl, 'https://x.test/sig.png');
      expect(records.first.photoFiles, ['https://x.test/p1.jpg']);
      // Phiếu cũ chưa lưu đường dẫn chữ ký vẫn không bị coi là nháp.
      expect(records.last.signatureUrl, startsWith('cloud:'));
    });
  });

  group('CloudAssetCatalogRepository', () {
    test('đọc danh mục từ máy chủ, sắp theo mã', () async {
      final repo = CloudAssetCatalogRepository(_Remote());
      final first = await repo.watchAll().first;
      expect(first.map((a) => a.code), ['TS-01', 'TS-02']);
      expect((await repo.findByCode('TS-02'))!.name, 'Tủ điện');
    });

    test('lưu là ghi thẳng lên máy chủ và phát lại danh mục', () async {
      final remote = _Remote();
      final repo = CloudAssetCatalogRepository(remote);
      await repo.watchAll().first;

      final next = repo.watchAll().skip(1).first;
      await repo.save(AssetModel('TS-03')..name = 'Máy chiếu');

      expect(remote.upserted.single['code'], 'TS-03');
      expect((await next).map((a) => a.code), contains('TS-03'));
      expect((await repo.sync()).conflicts, 0);
    });
  });

  group('Chế độ web (quản lý dữ liệu)', () {
    Future<ProviderContainer> pump(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          appModeProvider.overrideWithValue(AppMode.console),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(signedInAs: testUser),
          ),
          auditRecordsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('không có Quét mã, Phiếu kiểm kê, Đồng bộ trên thanh bên', (
      tester,
    ) async {
      await pump(tester, const Size(1440, 1000));

      expect(find.text('Tài sản & thiết bị'), findsWidgets);
      expect(find.text('Báo cáo'), findsOneWidget);
      expect(find.text('Quét mã & AI'), findsNothing);
      expect(find.text('Phiếu kiểm kê'), findsNothing);
      expect(find.text('Đồng bộ dữ liệu'), findsNothing);
      expect(find.text('Quét bằng app điện thoại'), findsOneWidget);
      expect(find.text('Xem báo cáo'), findsOneWidget);
    });

    testWidgets('mở đường dẫn quét thì quay về Tổng quan', (tester) async {
      final container = await pump(tester, const Size(1440, 1000));
      container.read(goRouterProvider).go('/scanner');
      await tester.pumpAndSettle();

      final router = container.read(goRouterProvider);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });

    testWidgets('mobile web: thanh dưới không có Quét mã', (tester) async {
      await pump(tester, const Size(400, 900));
      expect(find.text('Quét mã'), findsNothing);
      expect(find.text('Tài sản'), findsWidgets);
    });
  });

  test('isFieldOnlyPath', () {
    expect(isFieldOnlyPath('/scanner'), isTrue);
    expect(isFieldOnlyPath('/sync/conflicts'), isTrue);
    expect(isFieldOnlyPath('/assets'), isFalse);
    expect(isFieldOnlyPath('/settings'), isFalse);
    expect(GoRouter, isNotNull);
  });
}
