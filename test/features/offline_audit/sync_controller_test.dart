import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/supabase_sync_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/sync_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/sync_controller.dart';

class MockAuditRepository implements AuditRepository {
  @override
  Future<void> deleteRecord(int id) async {}

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
    return Uint8List(0);
  }
}

class MockSyncRepository implements SyncRepository {
  bool shouldThrow = false;
  List<AuditRecordModel> syncedRecords = [];

  @override
  Future<String?> uploadSignature(List<int> bytes) async {
    if (bytes.isEmpty) return null;
    return 'https://supabase.co/storage/v1/object/public/signatures/test.png';
  }

  @override
  Future<void> syncPendingRecords(List<AuditRecordModel> records) async {
    if (shouldThrow) {
      throw Exception('Lỗi kết nối mạng giả lập khi đồng bộ');
    }
    for (final r in records) {
      r.isSynced = true;
      syncedRecords.add(r);
    }
  }
}

void main() {
  group('SyncController Unit Tests', () {
    late MockAuditRepository mockAuditRepo;
    late MockSyncRepository mockSyncRepo;
    late ProviderContainer container;

    setUp(() {
      mockAuditRepo = MockAuditRepository();
      mockSyncRepo = MockSyncRepository();
      container = ProviderContainer(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(mockAuditRepo),
          syncRepositoryProvider.overrideWithValue(mockSyncRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is idle / AsyncData(null)', () {
      final state = container.read(syncControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('syncAll returns 0 when no pending records exist', () async {
      mockAuditRepo.records = [
        AuditRecordModel(1)..isSynced = true,
        AuditRecordModel(2)..isSynced = true,
      ];

      final notifier = container.read(syncControllerProvider.notifier);
      final count = await notifier.syncAll();

      expect(count, 0);
      expect(mockSyncRepo.syncedRecords, isEmpty);
      final state = container.read(syncControllerProvider);
      expect(state.hasError, isFalse);
    });

    test(
      'syncAll syncs pending records and returns successful count',
      () async {
        final pending1 = AuditRecordModel(1)
          ..scanCode = 'QR-001'
          ..quantity = 5
          ..signatureBytes = [1, 2, 3]
          ..isSynced = false;
        final pending2 = AuditRecordModel(2)
          ..scanCode = 'QR-002'
          ..quantity = 10
          ..signatureBytes = [1, 2, 3]
          ..isSynced = false;
        final alreadySynced = AuditRecordModel(3)
          ..scanCode = 'QR-003'
          ..quantity = 1
          ..isSynced = true;

        mockAuditRepo.records = [pending1, pending2, alreadySynced];

        final notifier = container.read(syncControllerProvider.notifier);
        final count = await notifier.syncAll();

        expect(count, 2);
        expect(mockSyncRepo.syncedRecords.length, 2);
        expect(pending1.isSynced, isTrue);
        expect(pending2.isSynced, isTrue);

        final state = container.read(syncControllerProvider);
        expect(state.hasError, isFalse);
      },
    );

    test('syncAll bỏ qua bản nháp chưa ký', () async {
      final draft = AuditRecordModel(1)
        ..scanCode = 'QR-DRAFT'
        ..quantity = 1
        ..isSynced = false;
      final signed = AuditRecordModel(2)
        ..scanCode = 'QR-SIGNED'
        ..quantity = 1
        ..signatureBytes = [1, 2, 3]
        ..isSynced = false;
      mockAuditRepo.records = [draft, signed];

      final count = await container
          .read(syncControllerProvider.notifier)
          .syncAll();

      expect(count, 1);
      expect(draft.isSynced, isFalse);
      expect(signed.isSynced, isTrue);
      expect(mockSyncRepo.syncedRecords, [signed]);
    });

    test(
      'syncAll sets AsyncError and rethrows on network/sync failure',
      () async {
        mockSyncRepo.shouldThrow = true;
        mockAuditRepo.records = [
          AuditRecordModel(1)
            ..scanCode = 'QR-FAIL'
            ..signatureBytes = [1, 2, 3]
            ..isSynced = false,
        ];

        final notifier = container.read(syncControllerProvider.notifier);

        await expectLater(notifier.syncAll(), throwsA(isA<Exception>()));

        final state = container.read(syncControllerProvider);
        expect(state.hasError, isTrue);
        expect(mockAuditRepo.records.first.isSynced, isFalse);
      },
    );
  });
}
