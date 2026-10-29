import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/asset_merge.dart';

final _t0 = DateTime.utc(2026, 10, 20);
final _t1 = DateTime.utc(2026, 10, 25);
final _now = DateTime.utc(2026, 10, 29);

AssetModel _asset(
  String code, {
  String name = 'Tủ điện',
  String? area = 'Xưởng A',
  int quantity = 1,
  String status = 'good',
  DateTime? lastAuditAt,
  DateTime? updatedAt,
  bool synced = true,
}) => AssetModel(code)
  ..name = name
  ..area = area
  ..quantity = quantity
  ..status = status
  ..lastAuditAt = lastAuditAt
  ..updatedAt = updatedAt ?? _t0
  ..isSynced = synced;

/// Tài sản đã sửa trên máy, mốc chung là [base].
AssetModel _edited(AssetModel base, void Function(AssetModel) edit) {
  final a = AssetModel.fromJson(base.toJson())
    ..isSynced = false
    ..updatedAt = _t1
    ..baseJson = jsonEncode(assetContent(base));
  edit(a);
  return a;
}

AssetModel _remote(AssetModel base, void Function(AssetModel) edit) {
  final a = AssetModel.fromJson(base.toJson())..updatedAt = _t1;
  edit(a);
  return a;
}

void main() {
  group('mergeAsset', () {
    final base = assetContent(_asset('A'));

    test('trường chỉ một bên sửa thì lấy bên đó, không xung đột', () {
      final m = mergeAsset(
        base: base,
        local: {...base, 'quantity': 3},
        remote: {...base, 'area': 'Kho B'},
      );
      expect(m.conflicts, isEmpty);
      expect(m.merged['quantity'], 3);
      expect(m.merged['area'], 'Kho B');
    });

    test('cả hai bên sửa cùng trường khác nhau thì xung đột', () {
      final m = mergeAsset(
        base: base,
        local: {...base, 'quantity': 3},
        remote: {...base, 'quantity': 5},
      );
      expect(m.conflicts, ['quantity']);
      expect(m.merged['quantity'], 3);
    });

    test('lần kiểm kê gần nhất cùng đổi thì lấy lần muộn hơn', () {
      final m = mergeAsset(
        base: base,
        local: {...base, 'last_audit_at': '2026-10-27T08:00:00.000Z'},
        remote: {...base, 'last_audit_at': '2026-10-28T08:00:00.000Z'},
      );
      expect(m.conflicts, isEmpty);
      expect(m.merged['last_audit_at'], '2026-10-28T08:00:00.000Z');
    });

    test('chưa có mốc chung thì mọi trường khác nhau đều cần chọn', () {
      final m = mergeAsset(
        base: null,
        local: {...base, 'name': 'Tủ điện tổng'},
        remote: {...base, 'area': 'Kho B'},
      );
      expect(m.conflicts, ['name', 'area']);
    });
  });

  group('planCatalogSync', () {
    test('tài sản không đổi trên máy: lấy bản máy chủ', () {
      final local = _asset('A');
      final remote = _remote(local, (a) => a.quantity = 9);
      final plan = planCatalogSync(locals: [local], remote: [remote]);

      expect(plan.toPush, isEmpty);
      expect(plan.toStore.single.quantity, 9);
      expect(plan.toStore.single.baseJson, isNotNull);
      expect(plan.conflicts, 0);
    });

    test('chỉ máy này sửa: đẩy bản trên máy lên', () {
      final base = _asset('A');
      final local = _edited(base, (a) => a.quantity = 4);
      final plan = planCatalogSync(locals: [local], remote: [base]);

      expect(plan.toPush.single.quantity, 4);
      expect(plan.toStore.single.isSynced, isTrue);
      expect(plan.conflicts, 0);
    });

    test('hai bên sửa khác trường: tự gộp và đẩy bản đã gộp', () {
      final base = _asset('A');
      final local = _edited(base, (a) => a.quantity = 4);
      final remote = _remote(base, (a) => a.area = 'Kho B');
      final plan = planCatalogSync(
        locals: [local],
        remote: [remote],
        now: _now,
      );

      final pushed = plan.toPush.single;
      expect(pushed.quantity, 4);
      expect(pushed.area, 'Kho B');
      expect(pushed.updatedAt.isAtSameMomentAs(_now), isTrue);
      expect(plan.conflicts, 0);
    });

    test('hai bên sửa cùng trường: không đẩy, không ghi đè, chờ đối chiếu', () {
      final base = _asset('A');
      final local = _edited(base, (a) => a.quantity = 4);
      final remote = _remote(base, (a) => a.quantity = 7);
      final plan = planCatalogSync(locals: [local], remote: [remote]);

      expect(plan.toPush, isEmpty);
      expect(plan.conflicts, 1);
      final stored = plan.toStore.single;
      expect(stored.quantity, 4);
      expect(stored.isSynced, isFalse);
      expect(stored.hasConflict, isTrue);
      expect(stored.conflictRemote!.quantity, 7);
    });

    test('tài sản mới trên máy: đẩy lên; tài sản mới trên máy chủ: kéo về', () {
      final mine = _asset('MOI', synced: false);
      final theirs = _asset('KHAC');
      final plan = planCatalogSync(locals: [mine], remote: [theirs]);

      expect(plan.toPush.map((a) => a.code), ['MOI']);
      expect(plan.toStore.map((a) => a.code), ['MOI', 'KHAC']);
    });
  });

  group('resolveAssetConflict', () {
    AssetModel conflicted() {
      final base = _asset('A');
      final local = _edited(base, (a) {
        a.quantity = 4;
        a.name = 'Tủ điện tổng';
      });
      final remote = _remote(base, (a) {
        a.quantity = 7;
        a.name = 'Tủ điện phụ';
      });
      return planCatalogSync(locals: [local], remote: [remote]).toStore.single;
    }

    test('chọn từng trường: giữ phần đã chọn, chờ đẩy lên', () {
      final resolved = resolveAssetConflict(conflicted(), {
        'quantity',
      }, now: _now)!;
      expect(resolved.quantity, 7);
      expect(resolved.name, 'Tủ điện tổng');
      expect(resolved.hasConflict, isFalse);
      expect(resolved.isSynced, isFalse);

      // Lần đồng bộ sau: máy chủ chưa đổi thêm nên đẩy thẳng lựa chọn lên.
      final remote = conflicted().conflictRemote!;
      final plan = planCatalogSync(locals: [resolved], remote: [remote]);
      expect(plan.toPush.single.name, 'Tủ điện tổng');
      expect(plan.conflicts, 0);
    });

    test('lấy toàn bộ bản máy chủ: không cần đẩy lại', () {
      final resolved = resolveAssetConflict(conflicted(), {
        ...assetFieldLabels.keys,
      })!;
      expect(resolved.quantity, 7);
      expect(resolved.name, 'Tủ điện phụ');
      expect(resolved.isSynced, isTrue);
    });

    test('tài sản không có xung đột thì bỏ qua', () {
      expect(resolveAssetConflict(_asset('A'), const {}), isNull);
    });
  });

  test('displayField hiển thị dễ đọc', () {
    expect(displayField('status', 'damaged'), isNot('damaged'));
    expect(displayField('area', null), '(trống)');
    expect(displayField('quantity', 3), '3');
  });
}
