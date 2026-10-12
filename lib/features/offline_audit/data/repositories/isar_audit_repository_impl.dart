import 'dart:typed_data';

import 'package:isar_plus/isar_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:field_inventory_edge_ai/core/database/local_db_init.dart';
import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';

part 'isar_audit_repository_impl.g.dart';

/// Implementation của [AuditRepository] sử dụng Isar Plus làm local database.
///
/// Tất cả thao tác ghi đều được thực hiện trong `write` transaction
/// để đảm bảo tính toàn vẹn dữ liệu.
class IsarAuditRepositoryImpl implements AuditRepository {
  /// Instance Isar được inject qua constructor (Dependency Injection).
  final Isar _isar;

  const IsarAuditRepositoryImpl(this._isar);

  @override
  Future<void> saveRecord(AuditRecordModel record) async {
    await _isar.writeAsync((isar) {
      if (record.id == 0) {
        final newId = isar.auditRecordModels.autoIncrement();
        final toSave = AuditRecordModel(newId)
          ..scanCode = record.scanCode
          ..aiDetectedLabel = record.aiDetectedLabel
          ..quantity = record.quantity
          ..signatureBytes = record.signatureBytes
          ..timestamp = record.timestamp ?? DateTime.now()
          ..isSynced = record.isSynced;
        isar.auditRecordModels.put(toSave);
      } else {
        isar.auditRecordModels.put(record);
      }
    });
  }

  @override
  Future<List<AuditRecordModel>> getAllRecords() async {
    return _isar.auditRecordModels.where().findAll();
  }

  @override
  Future<Uint8List> exportPdfReport() async {
    final records = _isar.auditRecordModels.where().findAll();
    return PdfReportGenerator.generateAuditReport(records);
  }
}

/// Riverpod provider cung cấp instance [AuditRepository] với tên [isarAuditRepositoryProvider].
///
/// Phụ thuộc vào [isarInstanceProvider] đã được khởi tạo trong `core/database/local_db_init.dart`.
@riverpod
AuditRepository isarAuditRepository(Ref ref) {
  final isar = ref.watch(isarInstanceProvider);
  return IsarAuditRepositoryImpl(isar);
}

/// Riverpod provider cung cấp instance [AuditRepository] (alias tương thích).
@riverpod
AuditRepository auditRepository(Ref ref) {
  return ref.watch(isarAuditRepositoryProvider);
}
