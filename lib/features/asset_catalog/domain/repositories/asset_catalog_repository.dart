import '../../data/models/asset_model.dart';

/// Kết quả một lần đồng bộ danh mục tài sản.
class CatalogSyncResult {
  const CatalogSyncResult({
    required this.pushed,
    required this.pulled,
    this.conflicts = 0,
  });

  /// Số tài sản sửa trên máy đã đẩy lên máy chủ.
  final int pushed;

  /// Số tài sản nhận về từ máy chủ.
  final int pulled;

  /// Số tài sản cả máy này và máy chủ cùng sửa khác nhau, chờ đối chiếu.
  final int conflicts;
}

/// Danh mục tài sản: lưu trên máy (offline) và đồng bộ với máy chủ.
abstract class AssetCatalogRepository {
  /// Toàn bộ danh mục trên máy, phát lại mỗi khi dữ liệu thay đổi.
  Stream<List<AssetModel>> watchAll();

  /// Tài sản có mã [code] trên máy, hoặc `null` nếu chưa có.
  Future<AssetModel?> findByCode(String code);

  /// Thêm hoặc sửa một tài sản trên máy, đánh dấu chờ đồng bộ.
  Future<void> save(AssetModel asset);

  /// Đẩy thay đổi trên máy lên rồi kéo danh mục mới nhất về.
  Future<CatalogSyncResult> sync();

  /// Chốt xung đột của tài sản [code]: lấy bản máy chủ cho các trường trong
  /// [useRemoteFields], giữ bản trên máy cho phần còn lại.
  Future<void> resolveConflict(String code, Set<String> useRemoteFields);
}

/// Nguồn dữ liệu danh mục trên máy chủ (Supabase).
abstract class AssetRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchAll();

  Future<void> upsert(List<Map<String, dynamic>> rows);
}
