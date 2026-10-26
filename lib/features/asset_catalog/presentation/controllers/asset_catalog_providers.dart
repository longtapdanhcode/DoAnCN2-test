import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_inventory_edge_ai/core/database/local_db_init.dart';
import 'package:field_inventory_edge_ai/core/network/supabase_provider.dart';

import '../../data/models/asset_model.dart';
import '../../data/repositories/asset_catalog_repository_impl.dart';
import '../../domain/repositories/asset_catalog_repository.dart';

final assetCatalogRepositoryProvider = Provider<AssetCatalogRepository>((ref) {
  return AssetCatalogRepositoryImpl(
    ref.watch(isarInstanceProvider),
    SupabaseAssetRemoteDataSource(ref.watch(supabaseClientProvider)),
  );
});

/// Danh mục tài sản trên máy, sắp theo mã.
final assetsProvider = StreamProvider<List<AssetModel>>((ref) {
  return ref.watch(assetCatalogRepositoryProvider).watchAll();
});
