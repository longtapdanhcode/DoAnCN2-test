import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/data/repositories/asset_catalog_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/entities/asset_status.dart';

AssetModel _asset(
  String code, {
  required DateTime updatedAt,
  bool synced = true,
}) => AssetModel(code)
  ..name = 'Tài sản $code'
  ..updatedAt = updatedAt
  ..isSynced = synced;

void main() {
  group('AssetModel JSON', () {
    test('round-trips through the Supabase row format', () {
      final asset = AssetModel('TS-DC-0142')
        ..name = 'Động cơ điện Siemens'
        ..category = 'Thiết bị truyền động'
        ..area = 'Xưởng sản xuất A'
        ..location = 'Kệ A3'
        ..quantity = 8
        ..status = AssetStatus.check.code
        ..lastAuditAt = DateTime.utc(2026, 10, 22, 9, 44)
        ..updatedAt = DateTime.utc(2026, 10, 23);

      final json = asset.toJson();
      expect(json['code'], 'TS-DC-0142');
      expect(json['status'], 'check');
      expect(json['last_audit_at'], '2026-10-22T09:44:00.000Z');

      final back = AssetModel.fromJson(json);
      expect(back.code, 'TS-DC-0142');
      expect(back.name, 'Động cơ điện Siemens');
      expect(back.area, 'Xưởng sản xuất A');
      expect(back.quantity, 8);
      expect(back.assetStatus, AssetStatus.check);
      expect(back.lastAuditAt!.toUtc(), DateTime.utc(2026, 10, 22, 9, 44));
      expect(back.isSynced, isTrue);
    });

    test('unknown status and missing fields fall back to defaults', () {
      final asset = AssetModel.fromJson({'code': 'X-1', 'status': 'lost'});
      expect(asset.name, '');
      expect(asset.quantity, 1);
      expect(asset.assetStatus, AssetStatus.good);
      expect(asset.lastAuditAt, isNull);
    });
  });

  group('shouldTakeRemote', () {
    final older = DateTime.utc(2026, 10, 20);
    final newer = DateTime.utc(2026, 10, 25);

    test('takes remote when there is no local copy', () {
      expect(shouldTakeRemote(null, _asset('A', updatedAt: older), {}), isTrue);
    });

    test('takes remote when the local copy is already synced', () {
      final local = _asset('A', updatedAt: newer);
      expect(
        shouldTakeRemote(local, _asset('A', updatedAt: older), {}),
        isTrue,
      );
    });

    test('keeps a newer unsynced local edit', () {
      final local = _asset('A', updatedAt: newer, synced: false);
      expect(
        shouldTakeRemote(local, _asset('A', updatedAt: older), {}),
        isFalse,
      );
    });

    test('takes remote when it is newer than the local edit', () {
      final local = _asset('A', updatedAt: older, synced: false);
      expect(
        shouldTakeRemote(local, _asset('A', updatedAt: newer), {}),
        isTrue,
      );
    });

    test('takes remote for edits that were just pushed', () {
      final local = _asset('A', updatedAt: newer, synced: false);
      expect(
        shouldTakeRemote(local, _asset('A', updatedAt: older), {'A'}),
        isTrue,
      );
    });
  });
}
