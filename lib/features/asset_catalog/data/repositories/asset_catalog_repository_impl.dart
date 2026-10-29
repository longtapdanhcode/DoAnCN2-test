import 'package:isar_plus/isar_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/asset_merge.dart';
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
    // Kéo bản máy chủ trước để biết bên nào đã đổi, rồi mới đẩy (Card 25):
    // không ghi đè thay đổi của thiết bị khác khi cả hai cùng sửa.
    final remote = [
      for (final row in await _remote.fetchAll()) AssetModel.fromJson(row),
    ];
    final plan = planCatalogSync(
      locals: _isar.assetModels.where().findAll(),
      remote: remote,
    );

    await _remote.upsert([for (final a in plan.toPush) a.toJson()]);
    await _isar.writeAsync((isar) => isar.assetModels.putAll(plan.toStore));

    return CatalogSyncResult(
      pushed: plan.toPush.length,
      pulled: remote.length,
      conflicts: plan.conflicts,
    );
  }

  @override
  Future<void> resolveConflict(String code, Set<String> useRemoteFields) async {
    final local = _isar.assetModels.get(code);
    if (local == null) return;
    final resolved = resolveAssetConflict(local, useRemoteFields);
    if (resolved == null) return;
    await _isar.writeAsync((isar) => isar.assetModels.put(resolved));
  }
}
