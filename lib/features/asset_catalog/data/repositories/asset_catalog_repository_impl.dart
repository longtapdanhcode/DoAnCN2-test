import 'package:isar_plus/isar_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/asset_catalog_repository.dart';
import '../models/asset_model.dart';

/// Đọc/ghi bảng `assets` trên Supabase.
class SupabaseAssetRemoteDataSource implements AssetRemoteDataSource {
  const SupabaseAssetRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _client.from('assets').select().order('code');
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> upsert(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('assets').upsert(rows, onConflict: 'code');
  }
}

/// Có ghi bản [incoming] từ máy chủ đè lên bản [local] trên máy không.
///
/// Giữ bản trên máy chỉ khi nó còn thay đổi chưa đẩy lên (không nằm trong
/// [pushedCodes]) và mới hơn bản máy chủ; các trường hợp khác lấy bản máy chủ.
bool shouldTakeRemote(
  AssetModel? local,
  AssetModel incoming,
  Set<String> pushedCodes,
) {
  if (local == null || local.isSynced) return true;
  if (pushedCodes.contains(local.code)) return true;
  return !local.updatedAt.isAfter(incoming.updatedAt);
}

/// Danh mục tài sản offline-first: Isar là nguồn hiển thị, Supabase là bản
/// dùng chung giữa các thiết bị.
class AssetCatalogRepositoryImpl implements AssetCatalogRepository {
  const AssetCatalogRepositoryImpl(this._isar, this._remote);

  final Isar _isar;
  final AssetRemoteDataSource _remote;

  @override
  Stream<List<AssetModel>> watchAll() {
    return _isar.assetModels.watchLazy(fireImmediately: true).map((_) {
      final assets = _isar.assetModels.where().findAll();
      assets.sort((a, b) => a.code.compareTo(b.code));
      return assets;
    });
  }

  @override
  Future<AssetModel?> findByCode(String code) async =>
      _isar.assetModels.get(code);

  @override
  Future<void> save(AssetModel asset) async {
    asset
      ..updatedAt = DateTime.now()
      ..isSynced = false;
    await _isar.writeAsync((isar) => isar.assetModels.put(asset));
  }

  @override
  Future<CatalogSyncResult> sync() async {
    // 1. Đẩy các tài sản sửa trên máy.
    final pending = _isar.assetModels.where().isSyncedEqualTo(false).findAll();
    await _remote.upsert([for (final a in pending) a.toJson()]);

    // 2. Kéo danh mục về. Bản trên máy chỉ bị ghi đè khi bản máy chủ mới hơn
    // hoặc bản trên máy đã đồng bộ (không còn thay đổi chờ đẩy).
    final remote = [
      for (final row in await _remote.fetchAll()) AssetModel.fromJson(row),
    ];
    final pushedCodes = {for (final a in pending) a.code};

    await _isar.writeAsync((isar) {
      for (final a in pending) {
        isar.assetModels.put(a..isSynced = true);
      }
      final toPut = <AssetModel>[];
      for (final incoming in remote) {
        final local = isar.assetModels.get(incoming.code);
        if (shouldTakeRemote(local, incoming, pushedCodes)) {
          toPut.add(incoming);
        }
      }
      isar.assetModels.putAll(toPut);
    });

    return CatalogSyncResult(pushed: pending.length, pulled: remote.length);
  }
}
