import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_form_controller.dart';

class MockAuditRepository implements AuditRepository {
  @override
  Future<void> deleteRecord(int id) async {
    records.removeWhere((r) => r.id == id);
  }

  final List<AuditRecordModel> records = [];
  bool shouldThrow = false;

  @override
  Future<void> saveRecord(AuditRecordModel record) async {
    if (shouldThrow) {
      throw Exception('Lỗi ghi cơ sở dữ liệu Isar giả lập');
    }
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

class _MemoryCatalog implements AssetCatalogRepository {
  _MemoryCatalog(List<AssetModel> initial)
    : items = {for (final a in initial) a.code: a};

  final Map<String, AssetModel> items;

  @override
  Stream<List<AssetModel>> watchAll() => Stream.value(items.values.toList());

  @override
  Future<AssetModel?> findByCode(String code) async => items[code];

  @override
  Future<void> save(AssetModel asset) async {
    items[asset.code] = asset..isSynced = false;
  }

  @override
  Future<CatalogSyncResult> sync() async =>
      const CatalogSyncResult(pushed: 0, pulled: 0);
}

void main() {
  group('AuditFormController Tests', () {
    late MockAuditRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockAuditRepository();
      container = ProviderContainer(
        overrides: [isarAuditRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is AuditFormStatus.initial', () {
      final state = container.read(auditFormControllerProvider);
      expect(state.status, AuditFormStatus.initial);
      expect(state.isSaving, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.hasError, isFalse);
    });

    test('submitForm succeeds and records data properly', () async {
      final notifier = container.read(auditFormControllerProvider.notifier);

      final result = await notifier.submitForm(
        scanCode: '  DEVICE-QR-12345  ',
        aiLabel: ' Laptop ',
        quantity: 3,
      );

      expect(result, isTrue);

      final state = container.read(auditFormControllerProvider);
      expect(state.status, AuditFormStatus.success);
      expect(state.isSuccess, isTrue);
      expect(state.hasError, isFalse);

      expect(mockRepo.records.length, 1);
      final saved = mockRepo.records.first;
      expect(saved.scanCode, 'DEVICE-QR-12345');
      expect(saved.aiDetectedLabel, 'Laptop');
      expect(saved.quantity, 3);
      expect(saved.timestamp, isNotNull);
      expect(saved.isSynced, isFalse);
    });

    test('submitForm saves field details and drops blank ones', () async {
      final notifier = container.read(auditFormControllerProvider.notifier);

      final result = await notifier.submitForm(
        scanCode: 'TS-DC-0142',
        aiLabel: 'Động cơ điện',
        quantity: 8,
        area: ' Xưởng sản xuất A ',
        location: '   ',
        condition: 'check',
        notes: 'Vỏ động cơ trầy xước.',
        assetName: ' Động cơ điện Siemens 3 pha ',
        signerName: 'Nguyễn Minh Anh',
        signerRole: '',
      );

      expect(result, isTrue);
      final saved = mockRepo.records.single;
      expect(saved.area, 'Xưởng sản xuất A');
      expect(saved.location, isNull);
      expect(saved.condition, 'check');
      expect(saved.notes, 'Vỏ động cơ trầy xước.');
      expect(saved.assetName, 'Động cơ điện Siemens 3 pha');
      expect(saved.signerName, 'Nguyễn Minh Anh');
      expect(saved.signerRole, isNull);
    });

    test('submitForm saves signatureBytes to AuditRecordModel', () async {
      final notifier = container.read(auditFormControllerProvider.notifier);
      final dummyBytes = [1, 2, 3, 4, 5, 255];

      final result = await notifier.submitForm(
        scanCode: 'DEVICE-SIG-999',
        aiLabel: 'Machine',
        quantity: 1,
        signatureBytes: dummyBytes,
      );

      expect(result, isTrue);
      expect(mockRepo.records.length, 1);
      final saved = mockRepo.records.first;
      expect(saved.signatureBytes, equals(dummyBytes));
    });

    test('submitForm handles errors when repository fails', () async {
      mockRepo.shouldThrow = true;
      final notifier = container.read(auditFormControllerProvider.notifier);

      final result = await notifier.submitForm(
        scanCode: 'FAIL-CODE',
        aiLabel: null,
        quantity: 1,
      );

      expect(result, isFalse);

      final state = container.read(auditFormControllerProvider);
      expect(state.status, AuditFormStatus.error);
      expect(state.hasError, isTrue);
      expect(state.errorMessage, contains('Lưu thất bại'));
      expect(mockRepo.records, isEmpty);
    });
  });

  group('Saving an audit updates the catalog asset', () {
    test('sets lastAuditAt and status for a known code', () async {
      final catalog = _MemoryCatalog([
        AssetModel('TS-DC-0142')
          ..name = 'Động cơ điện Siemens'
          ..status = 'good',
      ]);
      final container = ProviderContainer(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          assetCatalogRepositoryProvider.overrideWithValue(catalog),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(auditFormControllerProvider.notifier)
          .submitForm(
            scanCode: ' ts-dc-0142 ',
            quantity: 8,
            condition: 'damaged',
            signatureBytes: [1, 2, 3],
          );

      expect(ok, isTrue);
      final asset = catalog.items['TS-DC-0142']!;
      expect(asset.lastAuditAt, isNotNull);
      expect(asset.status, 'damaged');
      expect(asset.isSynced, isFalse);
    });

    test('unknown code still saves the audit', () async {
      final repo = MockAuditRepository();
      final container = ProviderContainer(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(repo),
          assetCatalogRepositoryProvider.overrideWithValue(_MemoryCatalog([])),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(auditFormControllerProvider.notifier)
          .submitForm(scanCode: 'NOT-IN-CATALOG', quantity: 1);

      expect(ok, isTrue);
      expect(repo.records, hasLength(1));
    });

    test('bản nháp (chưa ký) không cập nhật tài sản trong danh mục', () async {
      final catalog = _MemoryCatalog([
        AssetModel('TS-DC-0142')..name = 'Động cơ',
      ]);
      final container = ProviderContainer(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          assetCatalogRepositoryProvider.overrideWithValue(catalog),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(auditFormControllerProvider.notifier)
          .submitForm(
            scanCode: 'TS-DC-0142',
            quantity: 1,
            condition: 'damaged',
          );

      expect(ok, isTrue);
      expect(catalog.items['TS-DC-0142']!.lastAuditAt, isNull);
    });

    test(
      'hoàn tất bản nháp ghi đè đúng phiếu (cùng id) và có chữ ký',
      () async {
        final repo = MockAuditRepository();
        final container = ProviderContainer(
          overrides: [isarAuditRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        final ok = await container
            .read(auditFormControllerProvider.notifier)
            .submitForm(
              scanCode: 'TS-DC-0142',
              quantity: 3,
              signatureBytes: [1, 2, 3],
              signerName: 'Hoàng An',
              draftId: 7,
            );

        expect(ok, isTrue);
        expect(repo.records.single.id, 7);
        expect(repo.records.single.isDraft, isFalse);
      },
    );

    test('deleteDraft xoá bản nháp nhưng không xoá phiếu đã ký', () async {
      final repo = MockAuditRepository()
        ..records.addAll([
          AuditRecordModel(1)..scanCode = 'NHAP',
          AuditRecordModel(2)
            ..scanCode = 'DA-KY'
            ..signatureBytes = [1, 2, 3],
        ]);
      final container = ProviderContainer(
        overrides: [isarAuditRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(auditFormControllerProvider.notifier);

      expect(await notifier.deleteDraft(2), isFalse);
      expect(await notifier.deleteDraft(99), isFalse);
      expect(await notifier.deleteDraft(1), isTrue);
      expect(repo.records.map((r) => r.id), [2]);
    });
  });
}
