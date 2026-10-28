import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/entities/asset_status.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

/// Tiến độ kiểm kê của một khu vực trong kỳ.
class AreaProgress {
  const AreaProgress({
    required this.name,
    required this.planned,
    required this.done,
    required this.discrepancies,
  });

  final String name;

  /// Số tài sản của khu vực trong danh mục.
  final int planned;

  /// Số tài sản đã kiểm kê trong kỳ.
  final int done;

  /// Số phiếu trong kỳ có số lượng khác danh mục.
  final int discrepancies;

  double get progress => planned == 0 ? 0 : done / planned;
}

/// Số liệu Tổng quan & Báo cáo, tính từ danh mục tài sản và phiếu kiểm kê trên máy.
///
/// Kỳ báo cáo là tháng của [period] (mặc định tháng chứa [now]). Một tài sản được tính "đã kiểm kê" khi lần
/// kiểm kê gần nhất của nó rơi vào kỳ, hoặc có phiếu trong kỳ cùng mã.
class AuditStats {
  AuditStats._({
    required this.periodStart,
    required this.totalAssets,
    required this.auditedAssets,
    required this.needsCheck,
    required this.damaged,
    required this.discrepancies,
    required this.auditsToday,
    required this.auditsInPeriod,
    required this.areas,
  });

  factory AuditStats.compute({
    required List<AssetModel> assets,
    required List<AuditRecordModel> records,
    required DateTime now,
    DateTime? period,
  }) {
    final base = period ?? now;
    final periodStart = DateTime(base.year, base.month);
    final periodEnd = DateTime(base.year, base.month + 1);
    bool inPeriod(DateTime? t) =>
        t != null && !t.isBefore(periodStart) && t.isBefore(periodEnd);
    bool isToday(DateTime? t) =>
        t != null &&
        t.year == now.year &&
        t.month == now.month &&
        t.day == now.day;

    final periodRecords = records.where((r) => inPeriod(r.timestamp)).toList();
    final auditedCodes = <String>{
      for (final r in periodRecords)
        if (r.scanCode != null) r.scanCode!.trim().toUpperCase(),
      for (final a in assets)
        if (inPeriod(a.lastAuditAt)) a.code,
    };
    final byCode = {for (final a in assets) a.code: a};

    // Phiếu trong kỳ có số lượng đếm được khác danh mục.
    final discrepancyRecords = periodRecords.where((r) {
      final asset = byCode[r.scanCode?.trim().toUpperCase()];
      return asset != null && asset.quantity != r.quantity;
    }).toList();

    final areaNames = <String>{
      for (final a in assets) a.area ?? _noArea,
    }.toList()..sort();
    final areas = [
      for (final name in areaNames)
        () {
          final inArea = assets.where((a) => (a.area ?? _noArea) == name);
          return AreaProgress(
            name: name,
            planned: inArea.length,
            done: inArea.where((a) => auditedCodes.contains(a.code)).length,
            discrepancies: discrepancyRecords
                .where(
                  (r) =>
                      (byCode[r.scanCode?.trim().toUpperCase()]?.area ??
                          _noArea) ==
                      name,
                )
                .length,
          );
        }(),
    ];

    return AuditStats._(
      periodStart: periodStart,
      totalAssets: assets.length,
      auditedAssets: assets.where((a) => auditedCodes.contains(a.code)).length,
      needsCheck: assets
          .where(
            (a) =>
                a.assetStatus == AssetStatus.check ||
                a.assetStatus == AssetStatus.damaged,
          )
          .length,
      damaged: assets.where((a) => a.assetStatus == AssetStatus.damaged).length,
      discrepancies: discrepancyRecords.length,
      auditsToday: records.where((r) => isToday(r.timestamp)).length,
      auditsInPeriod: periodRecords.length,
      areas: areas,
    );
  }

  static const _noArea = 'Chưa có khu vực';

  /// Ngày đầu tháng của kỳ báo cáo.
  final DateTime periodStart;

  final int totalAssets;
  final int auditedAssets;

  /// Tài sản đang "Cần kiểm tra" hoặc "Hư hỏng".
  final int needsCheck;
  final int damaged;
  final int discrepancies;
  final int auditsToday;
  final int auditsInPeriod;
  final List<AreaProgress> areas;

  int get notAudited => totalAssets - auditedAssets;

  /// Tài sản đã kiểm kê mà không có sai lệch số lượng.
  int get matched => (auditedAssets - discrepancies).clamp(0, auditedAssets);

  double get progress => totalAssets == 0 ? 0 : auditedAssets / totalAssets;

  /// Nhãn kỳ, ví dụ "Tháng 10/2026".
  String get periodLabel => 'Tháng ${periodStart.month}/${periodStart.year}';

  /// Các tháng có phiếu kiểm kê (mới nhất trước), luôn gồm tháng của [now].
  static List<DateTime> availablePeriods(
    List<AuditRecordModel> records,
    DateTime now,
  ) {
    final months = <DateTime>{
      DateTime(now.year, now.month),
      for (final r in records)
        if (r.timestamp != null)
          DateTime(r.timestamp!.year, r.timestamp!.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    return months;
  }

  /// Nhãn tháng, ví dụ "Tháng 10/2026".
  static String labelOf(DateTime month) => 'Tháng ${month.month}/${month.year}';
}
