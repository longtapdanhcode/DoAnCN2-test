import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/supabase_sync_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/sync_settings_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/sync_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/auto_sync_controller.dart';

class _AuditRepo implements AuditRepository {
  List<AuditRecordModel> records = [];

  @override
  Future<void> deleteRecord(int id) async {}

  @override
  Future<void> saveRecord(AuditRecordModel record) async => records.add(record);

  @override
  Future<List<AuditRecordModel>> getAllRecords() async => records;

  @override
  Future<Uint8List> exportPdfReport() async => Uint8List(0);
}

class _SyncRepo implements SyncRepository {
  int failuresLeft = 0;
  int calls = 0;
  final sent = <String>[];

  @override
  Future<String?> uploadSignature(List<int> bytes) async => null;

  @override
  Future<String> uploadEvidencePhoto(List<int> bytes) async => 'url';

  @override
  Future<void> syncPendingRecords(List<AuditRecordModel> records) async {
    calls++;
    if (failuresLeft > 0) {
      failuresLeft--;
      throw Exception('mất kết nối giả lập');
    }
    for (final r in records) {
      r.isSynced = true;
      sent.add(r.scanCode!);
    }
  }
}

class _CatalogRepo implements AssetCatalogRepository {
  int syncs = 0;

  @override
  Stream<List<AssetModel>> watchAll() => Stream.value(const []);

  @override
  Future<AssetModel?> findByCode(String code) async => null;

  @override
  Future<void> save(AssetModel asset) async {}

  @override
  Future<CatalogSyncResult> sync() async {
    syncs++;
    return const CatalogSyncResult(pushed: 0, pulled: 0);
  }
}

class _MemorySettingsStore implements SyncSettingsStore {
  SyncSettings saved = const SyncSettings();

  @override
  Future<SyncSettings> load() async => saved;

  @override
  Future<void> save(SyncSettings settings) async => saved = settings;
}

AuditRecordModel _signed(int id, {bool photo = false}) => AuditRecordModel(id)
  ..scanCode = 'QR-$id'
  ..quantity = 1
  ..timestamp = DateTime(2026, 10, 29)
  ..signatureBytes = [1, 2, 3]
  ..photoFiles = photo ? ['ev_$id.jpg'] : null;

const _settle = Duration(milliseconds: 120);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AuditRepo auditRepo;
  late _SyncRepo syncRepo;
  late _CatalogRepo catalogRepo;
  late _MemorySettingsStore settingsStore;
  late StreamController<bool> online;
  late StreamController<bool> wifi;
  late StreamController<List<AuditRecordModel>> records;

  setUp(() {
    auditRepo = _AuditRepo();
    syncRepo = _SyncRepo();
    catalogRepo = _CatalogRepo();
    settingsStore = _MemorySettingsStore();
    online = StreamController<bool>();
    wifi = StreamController<bool>();
    records = StreamController<List<AuditRecordModel>>();
  });

  tearDown(() {
    online.close();
    wifi.close();
    records.close();
  });

  ProviderContainer start({bool isOnline = true, bool isWifi = true}) {
    final container = ProviderContainer(
      overrides: [
        isarAuditRepositoryProvider.overrideWithValue(auditRepo),
        syncRepositoryProvider.overrideWithValue(syncRepo),
        assetCatalogRepositoryProvider.overrideWithValue(catalogRepo),
        syncSettingsStoreProvider.overrideWithValue(settingsStore),
        isOnlineProvider.overrideWith((ref) => online.stream),
        isOnWifiProvider.overrideWith((ref) => wifi.stream),
        auditRecordsProvider.overrideWith((ref) => records.stream),
        autoSyncTimingsProvider.overrideWithValue(
          const AutoSyncTimings(
            debounce: Duration(milliseconds: 10),
            retryBase: Duration(milliseconds: 30),
            retryMax: Duration(milliseconds: 60),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Như khung app: có người theo dõi thì Riverpod mới không tạm dừng provider.
    container.listen(autoSyncProvider, (_, _) {});
    online.add(isOnline);
    wifi.add(isWifi);
    records.add(auditRepo.records);
    return container;
  }

  test('Có mạng và có phiếu đã ký: tự gửi lên không cần bấm', () async {
    auditRepo.records = [_signed(1), _signed(2)];
    final container = start();
    await Future<void>.delayed(_settle);

    expect(syncRepo.sent, ['QR-1', 'QR-2']);
    expect(catalogRepo.syncs, 1);
    final status = container.read(autoSyncStatusProvider);
    expect(status.lastCount, 2);
    expect(status.lastSyncedAt, isNotNull);
    expect(status.failures, 0);
  });

  test('Tắt tự đồng bộ thì không gửi gì', () async {
    settingsStore.saved = const SyncSettings(autoSync: false);
    auditRepo.records = [_signed(1)];
    start();
    await Future<void>.delayed(_settle);

    expect(syncRepo.calls, 0);
  });

  test('Bản nháp (chưa ký) không bao giờ được tự gửi', () async {
    auditRepo.records = [AuditRecordModel(5)..scanCode = 'NHAP'];
    start();
    await Future<void>.delayed(_settle);

    expect(syncRepo.calls, 0);
  });

  test('Ngoại tuyến thì chờ, có mạng trở lại thì tự gửi', () async {
    auditRepo.records = [_signed(1)];
    start(isOnline: false);
    await Future<void>.delayed(_settle);
    expect(syncRepo.calls, 0);

    online.add(true);
    await Future<void>.delayed(_settle);
    expect(syncRepo.sent, ['QR-1']);
  });

  test('Phiếu mới ký trong lúc app mở được gửi ngay sau đó', () async {
    final container = start();
    await Future<void>.delayed(_settle);
    expect(syncRepo.calls, 0);

    auditRepo.records = [_signed(7)];
    records.add(auditRepo.records);
    await Future<void>.delayed(_settle);
    expect(syncRepo.sent, ['QR-7']);
    expect(container.read(autoSyncStatusProvider).lastCount, 1);
  });

  test('Chỉ ảnh qua Wi-Fi: trên mạng di động phiếu có ảnh chờ Wi-Fi', () async {
    settingsStore.saved = const SyncSettings(wifiOnlyPhotos: true);
    auditRepo.records = [_signed(1), _signed(2, photo: true)];
    final container = start(isWifi: false);
    await Future<void>.delayed(_settle);

    expect(syncRepo.sent, ['QR-1']);
    expect(container.read(autoSyncStatusProvider).waitingForWifi, 1);

    wifi.add(true);
    await Future<void>.delayed(_settle);
    expect(syncRepo.sent, ['QR-1', 'QR-2']);
    expect(container.read(autoSyncStatusProvider).waitingForWifi, 0);
  });

  test('Lỗi mạng: tự thử lại sau một lúc rồi thành công', () async {
    syncRepo.failuresLeft = 1;
    auditRepo.records = [_signed(1)];
    final container = start();

    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(syncRepo.calls, 1);
    expect(container.read(autoSyncStatusProvider).failures, 1);
    expect(container.read(autoSyncStatusProvider).nextRetryAt, isNotNull);

    await Future<void>.delayed(_settle);
    expect(syncRepo.calls, 2);
    expect(syncRepo.sent, ['QR-1']);
    expect(container.read(autoSyncStatusProvider).failures, 0);
  });

  test('Đổi thiết lập được lưu lại cho lần mở app sau', () async {
    final container = start();
    await container.read(syncSettingsProvider.future);

    await container.read(syncSettingsProvider.notifier).setAutoSync(false);
    await container.read(syncSettingsProvider.notifier).setWifiOnlyPhotos(true);

    expect(
      settingsStore.saved,
      const SyncSettings(autoSync: false, wifiOnlyPhotos: true),
    );
  });

  test('Khoảng chờ thử lại nhân đôi và có giới hạn', () {
    const timings = AutoSyncTimings();
    expect(timings.retryAfter(1), const Duration(seconds: 30));
    expect(timings.retryAfter(2), const Duration(minutes: 1));
    expect(timings.retryAfter(3), const Duration(minutes: 2));
    expect(timings.retryAfter(10), const Duration(minutes: 5));
  });

  test('SyncSettings đọc/ghi JSON, thiếu khoá thì dùng mặc định', () {
    const s = SyncSettings(autoSync: false, wifiOnlyPhotos: true);
    expect(SyncSettings.fromJson(s.toJson()), s);
    expect(SyncSettings.fromJson(const {}), const SyncSettings());
  });
}
