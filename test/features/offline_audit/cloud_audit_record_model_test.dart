import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/core/network/supabase_config.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/cloud_audit_record_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAll') {
            return <String, dynamic>{};
          }
          return true;
        },
      );

  group('SupabaseConfig Tests', () {
    test('SupabaseConfig properties are valid strings', () {
      expect(SupabaseConfig.url, isA<String>());
      expect(SupabaseConfig.anonKey, isA<String>());
      expect(SupabaseConfig.publishableKey, equals(SupabaseConfig.anonKey));
      expect(SupabaseConfig.isConfigured, isA<bool>());
    });

    test('initSupabase completes successfully', () async {
      await expectLater(initSupabase(), completes);
    });
  });

  group('CloudAuditRecordModel Tests', () {
    test('Serialization to JSON uses snake_case keys for Supabase', () {
      const model = CloudAuditRecordModel(
        id: 'uuid-1234-5678',
        scanCode: 'ITEM-QR-001',
        aiDetectedLabel: 'Laptop',
        quantity: 5,
        timestamp: '2026-10-06T12:00:00.000Z',
        signatureUrl: 'https://storage.supabase.co/bucket/sig1.png',
      );

      final json = model.toJson();

      expect(json['id'], 'uuid-1234-5678');
      expect(json['scan_code'], 'ITEM-QR-001');
      expect(json['ai_detected_label'], 'Laptop');
      expect(json['quantity'], 5);
      expect(json['timestamp'], '2026-10-06T12:00:00.000Z');
      expect(
        json['signature_url'],
        'https://storage.supabase.co/bucket/sig1.png',
      );
    });

    test('Deserialization from JSON handles both snake_case and fallback', () {
      final json = {
        'id': 'uuid-9999',
        'scan_code': 'ITEM-BAR-999',
        'ai_detected_label': 'Monitor',
        'quantity': 2,
        'timestamp': '2026-10-06T12:30:00.000Z',
        'signature_url': null,
      };

      final model = CloudAuditRecordModel.fromJson(json);

      expect(model.id, 'uuid-9999');
      expect(model.scanCode, 'ITEM-BAR-999');
      expect(model.aiDetectedLabel, 'Monitor');
      expect(model.quantity, 2);
      expect(model.timestamp, '2026-10-06T12:30:00.000Z');
      expect(model.signatureUrl, isNull);
    });

    test('Field details map to snake_case columns and back', () {
      const model = CloudAuditRecordModel(
        id: 'uuid-details',
        scanCode: 'TS-DC-0142',
        quantity: 8,
        area: 'Xưởng sản xuất A',
        location: 'Kệ A3',
        condition: 'damaged',
        notes: 'Cần thay vòng bi',
        assetName: 'Động cơ điện Siemens',
        signerName: 'Nguyễn Minh Anh',
        signerRole: 'Tổ trưởng',
        timestamp: '2026-10-22T09:44:00.000Z',
      );

      final json = model.toJson();
      expect(json['asset_name'], 'Động cơ điện Siemens');
      expect(json['signer_name'], 'Nguyễn Minh Anh');
      expect(json['signer_role'], 'Tổ trưởng');
      expect(json['area'], 'Xưởng sản xuất A');
      expect(json['location'], 'Kệ A3');
      expect(json['condition'], 'damaged');
      expect(json['notes'], 'Cần thay vòng bi');
      expect(CloudAuditRecordModel.fromJson(json), model);

      // Trường trống không được gửi lên để không ghi đè cột bằng null.
      const bare = CloudAuditRecordModel(
        id: 'uuid-bare',
        scanCode: 'X',
        quantity: 1,
        timestamp: '2026-10-22T09:44:00.000Z',
      );
      expect(bare.toJson().containsKey('area'), isFalse);
      expect(bare.toJson().containsKey('notes'), isFalse);
    });

    test('fromAuditRecordModel converts local Isar model correctly', () {
      final localRecord = AuditRecordModel(10)
        ..scanCode = 'LOCAL-001'
        ..aiDetectedLabel = 'Chair'
        ..quantity = 12
        ..area = 'Kho trung tâm'
        ..condition = 'good'
        ..notes = 'OK'
        ..assetName = 'Ghế văn phòng'
        ..signerName = 'Hoàng An'
        ..timestamp = DateTime.utc(2026, 10, 6, 10, 0, 0);

      final cloudModel = CloudAuditRecordModel.fromAuditRecordModel(
        localRecord,
        id: 'cloud-uuid-abc',
        signatureUrl: 'https://supabase.co/sig.png',
      );

      expect(cloudModel.id, 'cloud-uuid-abc');
      expect(cloudModel.scanCode, 'LOCAL-001');
      expect(cloudModel.aiDetectedLabel, 'Chair');
      expect(cloudModel.quantity, 12);
      expect(cloudModel.area, 'Kho trung tâm');
      expect(cloudModel.location, isNull);
      expect(cloudModel.condition, 'good');
      expect(cloudModel.notes, 'OK');
      expect(cloudModel.assetName, 'Ghế văn phòng');
      expect(cloudModel.signerName, 'Hoàng An');
      expect(cloudModel.signerRole, isNull);
      expect(cloudModel.timestamp, '2026-10-06T10:00:00.000Z');
      expect(cloudModel.signatureUrl, 'https://supabase.co/sig.png');
    });
  });
}
