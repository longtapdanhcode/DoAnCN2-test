import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_form_controller.dart';

class MockAuditRepository implements AuditRepository {
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

void main() {
  group('AuditFormController Tests', () {
    late MockAuditRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockAuditRepository();
      container = ProviderContainer(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(mockRepo),
        ],
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
}
