import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/sync_settings_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/domain/audit_stats.dart';
import 'package:field_inventory_edge_ai/features/workspace/data/workspace_settings.dart';
import 'package:field_inventory_edge_ai/features/workspace/domain/area_summary.dart';
import 'package:field_inventory_edge_ai/features/workspace/presentation/screens/locations_screen.dart';
import 'package:field_inventory_edge_ai/features/workspace/presentation/screens/settings_screen.dart';

import '../../helpers/auth_fakes.dart';

class _WorkspaceStore implements WorkspaceSettingsStore {
  WorkspaceSettings saved = const WorkspaceSettings(
    siteName: 'Kho Tân Uyên',
    shift: 'Ca chiều',
  );

  @override
  Future<WorkspaceSettings> load() async => saved;

  @override
  Future<void> save(WorkspaceSettings settings) async => saved = settings;
}

class _SyncStore implements SyncSettingsStore {
  SyncSettings saved = const SyncSettings();

  @override
  Future<SyncSettings> load() async => saved;

  @override
  Future<void> save(SyncSettings settings) async => saved = settings;
}

AssetModel _asset(
  String code,
  String? area,
  String? location, {
  String status = 'good',
}) => AssetModel(code)
  ..name = 'Tài sản $code'
  ..area = area
  ..location = location
  ..status = status;

final _assets = [
  _asset('A1', 'Xưởng A', 'Kệ 1'),
  _asset('A2', 'Xưởng A', 'Kệ 1', status: 'damaged'),
  _asset('A3', 'Xưởng A', 'Kệ 2'),
  _asset('B1', 'Kho B', null),
  _asset('X1', null, null),
];

void main() {
  late _WorkspaceStore workspaceStore;
  late _SyncStore syncStore;

  Future<void> pump(WidgetTester tester, String initial) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    workspaceStore = _WorkspaceStore();
    syncStore = _SyncStore();
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/locations',
          builder: (_, _) => const Scaffold(body: LocationsScreen()),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const Scaffold(body: SettingsScreen()),
        ),
        GoRoute(
          path: '/assets',
          builder: (_, state) => Scaffold(
            body: Text('assets:${state.uri.queryParameters['area']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(signedInAs: testUser),
          ),
          assetsProvider.overrideWith((ref) => Stream.value(_assets)),
          auditRecordsProvider.overrideWith((ref) => Stream.value(const [])),
          workspaceSettingsStoreProvider.overrideWithValue(workspaceStore),
          syncSettingsStoreProvider.overrideWithValue(syncStore),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('buildAreaSummaries', () {
    test('đếm vị trí và tài sản cần xử lý theo khu vực', () {
      final stats = AuditStats.compute(
        assets: _assets,
        records: const [],
        now: DateTime(2026, 10, 29),
      );
      final areas = buildAreaSummaries(_assets, stats.areas);
      final a = areas.firstWhere((s) => s.name == 'Xưởng A');

      expect(a.progress.planned, 3);
      expect(a.needsAttention, 1);
      expect(a.positions.first.name, 'Kệ 1');
      expect(a.positions.first.assets, 2);
      expect(a.filterArea, 'Xưởng A');

      final none = areas.firstWhere((s) => s.name == AuditStats.noArea);
      expect(none.filterArea, isNull);
      expect(none.positions.single.name, 'Chưa ghi vị trí');
    });
  });

  testWidgets('Địa điểm: hiện khu vực và mở tài sản của khu vực', (
    tester,
  ) async {
    await pump(tester, '/locations');

    expect(find.text('Kho Tân Uyên'), findsOneWidget);
    expect(find.text('Xưởng A'), findsOneWidget);
    expect(find.text('Kho B'), findsOneWidget);
    expect(find.text('1 cần xử lý'), findsOneWidget);
    expect(find.text('Đã kiểm 0/3 tài sản'), findsOneWidget);

    await tester.tap(find.text('Xưởng A'));
    await tester.pumpAndSettle();
    expect(find.text('assets:Xưởng A'), findsOneWidget);
  });

  testWidgets('Cài đặt: đổi nơi kiểm kê và ca, lưu lại', (tester) async {
    await pump(tester, '/settings');

    expect(find.text('an@fieldline.vn'), findsOneWidget);
    expect(find.text('Kho Tân Uyên'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kho Tân Uyên'),
      'Nhà máy Long An',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ca đêm'));
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(
      workspaceStore.saved,
      const WorkspaceSettings(siteName: 'Nhà máy Long An', shift: 'Ca đêm'),
    );
    expect(find.text('Đã lưu nơi kiểm kê'), findsOneWidget);
  });

  testWidgets('Cài đặt: công tắc đồng bộ dùng chung thiết lập', (tester) async {
    await pump(tester, '/settings');

    await tester.tap(find.text('Chỉ tải ảnh qua Wi-Fi'));
    await tester.pumpAndSettle();
    expect(syncStore.saved.wifiOnlyPhotos, isTrue);
  });

  test('WorkspaceSettings: JSON thiếu/sai thì dùng mặc định', () {
    const s = WorkspaceSettings(siteName: 'Kho 1', shift: 'Ca đêm');
    expect(WorkspaceSettings.fromJson(s.toJson()), s);
    expect(
      WorkspaceSettings.fromJson(const {'site_name': ' ', 'shift': 'Ca 9'}),
      const WorkspaceSettings(),
    );
    expect(s.summary, 'Kho 1  ·  Ca đêm');
  });
}
