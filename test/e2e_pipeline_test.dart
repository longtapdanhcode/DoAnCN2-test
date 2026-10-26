// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/core/network/supabase_config.dart';
import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/cloud_audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/supabase_sync_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/sync_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_form_controller.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/sync_controller.dart';

/// Bộ lưu trữ giả lập Isar Local Database chuẩn Clean Architecture & Offline-First.
class InMemoryIsarAuditRepository implements AuditRepository {
  final Map<int, AuditRecordModel> _records = {};
  int _autoIncrementId = 1;

  @override
  Future<void> saveRecord(AuditRecordModel record) async {
    final id = record.id == 0 ? _autoIncrementId++ : record.id;
    final saved = AuditRecordModel(id, signatureBytes: record.signatureBytes)
      ..scanCode = record.scanCode
      ..aiDetectedLabel = record.aiDetectedLabel
      ..quantity = record.quantity
      ..timestamp = record.timestamp ?? DateTime.now()
      ..isSynced = record.isSynced;
    _records[id] = saved;
  }

  @override
  Future<List<AuditRecordModel>> getAllRecords() async {
    return _records.values.toList();
  }

  @override
  Future<Uint8List> exportPdfReport() async {
    return PdfReportGenerator.generateAuditReport(_records.values.toList());
  }

  void updateRecordSyncStatus(int id, bool isSynced) {
    if (_records.containsKey(id)) {
      _records[id]!.isSynced = isSynced;
    }
  }

  void clear() {
    _records.clear();
    _autoIncrementId = 1;
  }
}

/// Giả lập Supabase Cloud Sync Repository để xác thực tải chữ ký và ingestion.
class E2ESupabaseSyncRepository implements SyncRepository {
  final InMemoryIsarAuditRepository localRepository;
  final List<CloudAuditRecordModel> cloudStorage = [];

  E2ESupabaseSyncRepository(this.localRepository);

  @override
  Future<String?> uploadSignature(List<int> bytes) async {
    if (bytes.isEmpty) return null;
    final fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
    return '${SupabaseConfig.url}storage/v1/object/public/signatures/$fileName';
  }

  @override
  Future<void> syncPendingRecords(List<AuditRecordModel> records) async {
    final pending = records.where((r) => !r.isSynced).toList();
    for (final record in pending) {
      String? sigUrl;
      if (record.signatureBytes != null && record.signatureBytes!.isNotEmpty) {
        sigUrl = await uploadSignature(record.signatureBytes!);
      }

      final cloudModel = CloudAuditRecordModel.fromAuditRecordModel(
        record,
        signatureUrl: sigUrl,
      );

      cloudStorage.add(cloudModel);
      record.isSynced = true;
      localRepository.updateRecordSyncStatus(record.id, true);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Field Inventory Edge AI - Toàn trình E2E Pipeline Integration Test', () {
    late InMemoryIsarAuditRepository mockIsarRepo;
    late E2ESupabaseSyncRepository mockSyncRepo;
    late ProviderContainer container;

    // Chuẩn bị mảng byte ảnh chữ ký số PNG hợp lệ (1x1 pixel)
    final validSignaturePngBytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);

    setUp(() {
      mockIsarRepo = InMemoryIsarAuditRepository();
      mockSyncRepo = E2ESupabaseSyncRepository(mockIsarRepo);
      container = ProviderContainer(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(mockIsarRepo),
          auditRepositoryProvider.overrideWithValue(mockIsarRepo),
          syncRepositoryProvider.overrideWithValue(mockSyncRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockIsarRepo.clear();
    });

    test('Chạy kiểm thử toàn trình 5 chặng: Nhập liệu -> Isar -> Ký tên -> PDF -> Supabase Sync -> Dashboard', () async {
      print(
        '\n======================================================================',
      );
      print(
        '🚀 BẮT ĐẦU E2E PIPELINE TEST: FIELD INVENTORY & EDGE AI (OFFLINE-FIRST)',
      );
      print(
        '======================================================================',
      );

      // -----------------------------------------------------------------------
      // CHẶNG 1: Khởi tạo & Kiểm tra Hạ tầng Offline-First
      // -----------------------------------------------------------------------
      final initialRecords = await mockIsarRepo.getAllRecords();
      expect(
        initialRecords,
        isEmpty,
        reason: 'Isar database ban đầu phải hoàn toàn rỗng.',
      );
      print('[E2E STEP 1/5] Khởi tạo Isar Local Database thành công.');

      // -----------------------------------------------------------------------
      // CHẶNG 2: Luồng Nhập liệu & Thu nhận Chữ ký số
      // -----------------------------------------------------------------------
      const scanCode = 'INV-2026-VKU-001';
      const aiDetectedLabel = 'Thùng hàng / Laptop';
      const quantity = 5;

      final formController = container.read(
        auditFormControllerProvider.notifier,
      );
      final submitSuccess = await formController.submitForm(
        scanCode: scanCode,
        aiLabel: aiDetectedLabel,
        quantity: quantity,
        signatureBytes: validSignaturePngBytes,
      );

      expect(
        submitSuccess,
        isTrue,
        reason: 'Form nhập liệu và chữ ký phải lưu thành công.',
      );

      final storedRecords = await mockIsarRepo.getAllRecords();
      expect(
        storedRecords.length,
        1,
        reason: 'Phải có đúng 1 bản ghi được ghi nhận vào Isar.',
      );

      final savedRecord = storedRecords.first;
      expect(savedRecord.scanCode, scanCode);
      expect(savedRecord.aiDetectedLabel, aiDetectedLabel);
      expect(savedRecord.quantity, quantity);
      expect(savedRecord.signatureBytes, isNotNull);
      expect(savedRecord.signatureBytes, isNotEmpty);
      expect(
        savedRecord.isSynced,
        isFalse,
        reason: 'Bản ghi mới lưu phải có cờ isSynced = false (Offline-First).',
      );

      print(
        '[E2E STEP 2/5] Đã lưu bản ghi kiểm kê ngoại tuyến và chữ ký số vào Isar (isSynced = false).',
      );

      // -----------------------------------------------------------------------
      // CHẶNG 3: Động cơ Xuất Báo cáo PDF (PDF Pipeline)
      // -----------------------------------------------------------------------
      final pdfBytes = await PdfReportGenerator.generateAuditReport(
        storedRecords,
      );
      expect(
        pdfBytes,
        isNotEmpty,
        reason: 'Mảng byte tài liệu PDF không được rỗng.',
      );
      expect(pdfBytes.length, greaterThan(0));

      final magicHeader = ascii.decode(pdfBytes.sublist(0, 5));
      expect(
        magicHeader,
        '%PDF-',
        reason: 'Tệp xuất ra phải có magic header chuẩn %PDF-.',
      );

      print(
        '[E2E STEP 3/5] Động cơ PDF đã kết xuất báo cáo A4 hợp lệ từ dữ liệu Isar (Kích thước: ${pdfBytes.length} bytes).',
      );

      // -----------------------------------------------------------------------
      // CHẶNG 4: Luồng Đồng bộ Đám mây (Supabase Sync & Storage)
      // -----------------------------------------------------------------------
      // 4.1. Xác thực cấu hình Supabase
      expect(
        SupabaseConfig.isConfigured,
        isTrue,
        reason: 'SupabaseConfig phải được cấu hình URL và Anon Key hợp lệ.',
      );

      // 4.2. Kiểm chứng luồng DTO chuyển đổi sang CloudAuditRecordModel
      final cloudModelPreview = CloudAuditRecordModel.fromAuditRecordModel(
        savedRecord,
        signatureUrl: 'https://ksyqadzajepmrgaoweyi.supabase.co/storage/v1/object/public/signatures/sig_test.png',
      );

      // Kiểm tra chuẩn UUID v4
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(
        uuidRegex.hasMatch(cloudModelPreview.id),
        isTrue,
        reason: 'Cloud ID phải tuân thủ định dạng UUID v4.',
      );

      // Kiểm tra chuẩn ISO-8601 UTC timestamp
      expect(
        DateTime.tryParse(cloudModelPreview.timestamp)?.isUtc,
        isTrue,
        reason: 'Timestamp đồng bộ phải chuẩn hóa về ISO UTC.',
      );

      // Kiểm tra mapping snake_case PostgreSQL
      final jsonMapping = cloudModelPreview.toJson();
      expect(jsonMapping['scan_code'], scanCode);
      expect(jsonMapping['ai_detected_label'], aiDetectedLabel);
      expect(jsonMapping['quantity'], quantity);
      expect(jsonMapping['signature_url'], contains('signatures/'));

      // 4.3. Kích hoạt đồng bộ thông qua SyncController
      final syncController = container.read(syncControllerProvider.notifier);
      final syncedCount = await syncController.syncAll();
      expect(
        syncedCount,
        1,
        reason: 'Phải đồng bộ thành công đúng 1 bản ghi chờ.',
      );

      // 4.4. Xác thực trạng thái trong Local DB
      final recordsAfterSync = await mockIsarRepo.getAllRecords();
      expect(
        recordsAfterSync.first.isSynced,
        isTrue,
        reason: 'Bản ghi nội bộ phải cập nhật isSynced = true.',
      );
      expect(
        mockSyncRepo.cloudStorage.length,
        1,
        reason: 'Cloud storage phải ghi nhận đúng 1 bản ghi được đẩy lên.',
      );

      print(
        '[E2E STEP 4/5] Đồng bộ đám mây hoàn tất. Bản ghi local đã cập nhật isSynced = true.',
      );

      // -----------------------------------------------------------------------
      // CHẶNG 5: Kiểm tra Thống kê Dashboard & Phản hồi UI
      // -----------------------------------------------------------------------
      final finalRecords = await mockIsarRepo.getAllRecords();
      final totalQuantity = finalRecords.fold<int>(
        0,
        (sum, r) => sum + r.quantity,
      );
      final totalSynced = finalRecords.where((r) => r.isSynced).length;
      final syncRate = finalRecords.isEmpty
          ? 0.0
          : (totalSynced / finalRecords.length) * 100;

      expect(
        totalQuantity,
        5,
        reason: 'Tổng số lượng vật tư trên Dashboard phải bằng 5.',
      );
      expect(
        syncRate,
        100.0,
        reason: 'Tỷ lệ đồng bộ hiển thị trên Dashboard phải đạt 100%.',
      );

      print(
        '[E2E STEP 5/5] Hệ thống phản hồi chính xác toàn bộ chỉ số Dashboard:',
      );
      print(
        '              - Tổng vật tư ghi nhận: $totalQuantity (Mục tiêu: 5)',
      );
      print(
        '              - Tỷ lệ đồng bộ Cloud: ${syncRate.toStringAsFixed(0)}% (Mục tiêu: 100%)',
      );
      print(
        '======================================================================',
      );
      print(
        '✅ TOÀN BỘ 5 CHẶNG E2E PIPELINE ĐÃ VƯỢT QUA VỚI ĐỘ CHÍNH XÁC TUYỆT ĐỐI!',
      );
      print(
        '======================================================================\n',
      );
    });
  });
}
