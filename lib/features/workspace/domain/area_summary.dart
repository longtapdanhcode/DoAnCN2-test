import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/entities/asset_status.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/domain/audit_stats.dart';

/// Số tài sản ở một vị trí cụ thể trong khu vực.
class PositionCount {
  const PositionCount(this.name, this.assets);

  final String name;
  final int assets;
}

/// Một khu vực ở màn Địa điểm: tiến độ kỳ này cùng các vị trí bên trong.
class AreaSummary {
  const AreaSummary({
    required this.progress,
    required this.needsAttention,
    required this.positions,
  });

  final AreaProgress progress;

  /// Tài sản "Cần kiểm tra" hoặc "Hư hỏng".
  final int needsAttention;

  /// Vị trí trong khu vực, nhiều tài sản nhất lên trước.
  final List<PositionCount> positions;

  String get name => progress.name;

  /// Tên khu vực để lọc danh mục (`null` với nhóm "chưa có khu vực").
  String? get filterArea =>
      progress.name == AuditStats.noArea ? null : progress.name;
}

/// Ghép tiến độ theo khu vực [areas] với danh mục [assets].
List<AreaSummary> buildAreaSummaries(
  List<AssetModel> assets,
  List<AreaProgress> areas,
) {
  return [
    for (final area in areas)
      () {
        final inArea = assets
            .where((a) => (a.area ?? AuditStats.noArea) == area.name)
            .toList();
        final counts = <String, int>{};
        for (final a in inArea) {
          final pos = (a.location?.trim().isNotEmpty ?? false)
              ? a.location!.trim()
              : 'Chưa ghi vị trí';
          counts[pos] = (counts[pos] ?? 0) + 1;
        }
        final positions =
            [for (final e in counts.entries) PositionCount(e.key, e.value)]
              ..sort((a, b) {
                final byCount = b.assets.compareTo(a.assets);
                return byCount != 0 ? byCount : a.name.compareTo(b.name);
              });
        return AreaSummary(
          progress: area,
          needsAttention: inArea
              .where(
                (a) =>
                    a.assetStatus == AssetStatus.check ||
                    a.assetStatus == AssetStatus.damaged,
              )
              .length,
          positions: positions,
        );
      }(),
  ];
}
