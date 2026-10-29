import 'dart:convert';

import '../data/models/asset_model.dart';
import 'entities/asset_status.dart';

/// Các trường của tài sản được đối chiếu khi đồng bộ, theo thứ tự hiển thị.
const assetFieldLabels = <String, String>{
  'name': 'Tên tài sản',
  'category': 'Loại thiết bị',
  'area': 'Khu vực',
  'location': 'Vị trí',
  'quantity': 'Số lượng',
  'status': 'Tình trạng',
  'last_audit_at': 'Lần kiểm kê gần nhất',
};

/// Nội dung của tài sản để so sánh giữa các phiên bản (bỏ mã và thời điểm sửa).
Map<String, Object?> assetContent(AssetModel a) => a.toJson()
  ..remove('code')
  ..remove('updated_at');

/// Đọc nội dung đã lưu dạng JSON (ví dụ [AssetModel.baseJson]).
Map<String, Object?>? decodeContent(String? json) {
  if (json == null) return null;
  final value = jsonDecode(json);
  return value is Map<String, dynamic> ? value : null;
}

/// Hai bản có cùng nội dung không.
bool sameContent(Map<String, Object?> a, Map<String, Object?> b) =>
    assetFieldLabels.keys.every((k) => a[k] == b[k]);

/// Các trường khác nhau giữa hai bản.
List<String> differingFields(Map<String, Object?> a, Map<String, Object?> b) =>
    [
      for (final k in assetFieldLabels.keys)
        if (a[k] != b[k]) k,
    ];

/// Giá trị dễ đọc của một trường, dùng ở màn đối chiếu.
String displayField(String key, Object? value) {
  if (value == null || value == '') return '(trống)';
  switch (key) {
    case 'status':
      return AssetStatus.fromCode(value as String).label;
    case 'last_audit_at':
      final d = DateTime.tryParse(value as String)?.toLocal();
      if (d == null) return value;
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    default:
      return '$value';
  }
}

/// Kết quả gộp ba chiều một tài sản.
class AssetMerge {
  const AssetMerge(this.merged, this.conflicts);

  /// Nội dung sau khi gộp; trường xung đột tạm giữ giá trị trên máy.
  final Map<String, Object?> merged;

  /// Các trường cả hai bên cùng sửa khác nhau, cần người dùng chọn.
  final List<String> conflicts;
}

/// Gộp bản trên máy [local] và bản đám mây [remote] dựa trên bản chung gần
/// nhất [base] (lần cuối hai bên khớp nhau).
///
/// Trường chỉ một bên sửa thì lấy bên đó. Lần kiểm kê gần nhất cả hai bên
/// cùng đổi thì lấy lần muộn hơn. Không có [base] (chưa từng khớp) thì mọi
/// trường khác nhau đều cần chọn.
AssetMerge mergeAsset({
  required Map<String, Object?>? base,
  required Map<String, Object?> local,
  required Map<String, Object?> remote,
}) {
  final merged = <String, Object?>{};
  final conflicts = <String>[];
  for (final key in assetFieldLabels.keys) {
    final l = local[key];
    final r = remote[key];
    if (l == r) {
      merged[key] = l;
    } else if (base != null && l == base[key]) {
      merged[key] = r;
    } else if (base != null && r == base[key]) {
      merged[key] = l;
    } else if (key == 'last_audit_at') {
      merged[key] = _later(l as String?, r as String?);
    } else {
      merged[key] = l;
      conflicts.add(key);
    }
  }
  return AssetMerge(merged, conflicts);
}

String? _later(String? a, String? b) {
  final da = a == null ? null : DateTime.tryParse(a);
  final db = b == null ? null : DateTime.tryParse(b);
  if (da == null) return b;
  if (db == null) return a;
  return da.isAfter(db) ? a : b;
}

/// Tạo tài sản [code] từ nội dung [content].
AssetModel assetFromContent(
  String code,
  Map<String, Object?> content, {
  required DateTime updatedAt,
}) => AssetModel.fromJson({
  ...content,
  'code': code,
  'updated_at': updatedAt.toUtc().toIso8601String(),
});

/// Kế hoạch một lần đồng bộ danh mục: tính trước, rồi mới gọi máy chủ và ghi Isar.
class CatalogSyncPlan {
  const CatalogSyncPlan({
    required this.toPush,
    required this.toStore,
    required this.conflicts,
  });

  /// Tài sản cần đẩy lên máy chủ.
  final List<AssetModel> toPush;

  /// Tài sản cần ghi vào Isar sau khi đẩy thành công.
  final List<AssetModel> toStore;

  /// Số tài sản đang chờ người dùng đối chiếu.
  final int conflicts;
}

/// Lập kế hoạch đồng bộ từ danh mục trên máy [locals] và trên máy chủ [remote].
///
/// - Tài sản trên máy không có thay đổi: lấy bản máy chủ.
/// - Có thay đổi và máy chủ không đổi kể từ lần khớp gần nhất: đẩy bản trên máy.
/// - Cả hai bên cùng đổi: gộp ba chiều; còn trường xung đột thì giữ bản trên
///   máy, lưu kèm bản máy chủ và chờ người dùng chọn (không đẩy, không ghi đè).
CatalogSyncPlan planCatalogSync({
  required List<AssetModel> locals,
  required List<AssetModel> remote,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final remoteByCode = {for (final r in remote) r.code: r};
  final toPush = <AssetModel>[];
  final toStore = <AssetModel>[];
  var conflicts = 0;

  void stored(AssetModel a, Map<String, Object?> base) {
    toStore.add(
      a
        ..isSynced = true
        ..baseJson = jsonEncode(base)
        ..conflictJson = null,
    );
  }

  for (final local in locals) {
    final r = remoteByCode.remove(local.code);
    if (local.isSynced) {
      if (r != null) stored(r, assetContent(r));
      continue;
    }

    final localContent = assetContent(local);
    if (r == null) {
      toPush.add(local);
      stored(local, localContent);
      continue;
    }

    final remoteContent = assetContent(r);
    final base = decodeContent(local.baseJson);
    if (base != null && sameContent(base, remoteContent)) {
      toPush.add(local);
      stored(local, localContent);
      continue;
    }

    final merge = mergeAsset(
      base: base,
      local: localContent,
      remote: remoteContent,
    );
    if (merge.conflicts.isEmpty) {
      final merged = assetFromContent(local.code, merge.merged, updatedAt: at);
      if (!sameContent(merge.merged, remoteContent)) toPush.add(merged);
      stored(merged, merge.merged);
    } else {
      conflicts++;
      toStore.add(local..conflictJson = jsonEncode(r.toJson()));
    }
  }

  // Tài sản mới trên máy chủ, máy này chưa có.
  for (final r in remoteByCode.values) {
    stored(r, assetContent(r));
  }

  return CatalogSyncPlan(
    toPush: toPush,
    toStore: toStore,
    conflicts: conflicts,
  );
}

/// Chốt một xung đột: lấy bản máy chủ cho các trường trong [useRemoteFields],
/// còn lại giữ bản trên máy. Trả về `null` nếu tài sản không còn xung đột.
///
/// Bản chung mới là bản máy chủ, nên lần đồng bộ sau sẽ đẩy lựa chọn lên
/// (hoặc không cần đẩy nếu đã chọn toàn bộ bản máy chủ).
AssetModel? resolveAssetConflict(
  AssetModel local,
  Set<String> useRemoteFields, {
  DateTime? now,
}) {
  final remote = local.conflictRemote;
  if (remote == null) return null;
  final localContent = assetContent(local);
  final remoteContent = assetContent(remote);
  final chosen = {
    for (final k in assetFieldLabels.keys)
      k: useRemoteFields.contains(k) ? remoteContent[k] : localContent[k],
  };
  final takesRemote = sameContent(chosen, remoteContent);
  return assetFromContent(
      local.code,
      chosen,
      updatedAt: takesRemote ? remote.updatedAt : (now ?? DateTime.now()),
    )
    ..isSynced = takesRemote
    ..baseJson = jsonEncode(remoteContent)
    ..conflictJson = null;
}
