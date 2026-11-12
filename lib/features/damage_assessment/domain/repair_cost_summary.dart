import 'package:flutter/foundation.dart';

import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

import 'entities/damage_enums.dart';
import 'entities/surface_assessment.dart';

/// Một bề mặt đã đánh giá (phiếu mới nhất của mã đó trong tập phiếu).
@immutable
class AssessedSurface {
  const AssessedSurface({required this.record, required this.assessment});

  final AuditRecordModel record;
  final SurfaceAssessment assessment;

  String get code => record.scanCode?.trim() ?? '';
  String get name => record.assetName ?? code;
  String get building => _clean(record.area) ?? RepairCostSummary.noBuilding;
  String get room => _clean(record.location) ?? RepairCostSummary.noRoom;
  double get cost => assessment.totalCost;
  double get score => assessment.conditionScore;
  DamageSeverity? get worst => assessment.worstSeverity;

  static String? _clean(String? v) =>
      v == null || v.trim().isEmpty ? null : v.trim();
}

/// Tổng hợp chi phí và điểm của một nhóm (tòa nhà hoặc phòng).
@immutable
class CostGroup {
  const CostGroup({
    required this.name,
    required this.surfaces,
    required this.cost,
    required this.averageScore,
    required this.worst,
    this.building,
  });

  final String name;

  /// Tên tòa nhà (chỉ có với nhóm phòng).
  final String? building;
  final int surfaces;
  final double cost;
  final double averageScore;
  final DamageSeverity? worst;
}

/// Số liệu chi phí sửa chữa cho Tổng quan, Báo cáo và PDF.
///
/// - Chỉ tính phiếu đã ký có đánh giá hư hỏng.
/// - Một bề mặt (cùng mã) kiểm kê nhiều lần thì lấy phiếu mới nhất, để không
///   cộng tiền hai lần.
/// - Điểm cơ sở vật chất = trung bình điểm tình trạng các bề mặt (0..100).
class RepairCostSummary {
  RepairCostSummary._(this.surfaces);

  factory RepairCostSummary.fromRecords(Iterable<AuditRecordModel> records) {
    final latest = <String, AssessedSurface>{};
    var anonymous = 0;
    for (final r in records) {
      if (r.isDraft) continue;
      final a = r.surfaceAssessment;
      if (a == null) continue;
      final code = r.scanCode?.trim().toUpperCase() ?? '';
      // Phiếu không có mã: mỗi phiếu là một bề mặt riêng.
      final key = code.isEmpty ? '#${anonymous++}' : code;
      final current = latest[key];
      final t = r.timestamp;
      final ct = current?.record.timestamp;
      if (current == null || (t != null && (ct == null || t.isAfter(ct)))) {
        latest[key] = AssessedSurface(record: r, assessment: a);
      }
    }
    final list = latest.values.toList()..sort(_priority);
    return RepairCostSummary._(List.unmodifiable(list));
  }

  static const noBuilding = 'Chưa ghi tòa nhà';
  static const noRoom = 'Chưa ghi phòng';

  /// Các bề mặt, xếp theo mức ưu tiên sửa (nặng trước, rồi tiền nhiều trước).
  final List<AssessedSurface> surfaces;

  bool get isEmpty => surfaces.isEmpty;
  int get count => surfaces.length;

  double get totalCost => surfaces.fold(0, (s, e) => s + e.cost);

  /// Điểm cơ sở vật chất 0..100; `null` khi chưa đánh giá bề mặt nào.
  double? get facilityScore => surfaces.isEmpty
      ? null
      : surfaces.fold<double>(0, (s, e) => s + e.score) / surfaces.length;

  int countWorst(DamageSeverity severity) =>
      surfaces.where((s) => s.worst == severity).length;

  /// Tiền theo loại hư hỏng (chỉ loại có tiền).
  Map<DamageType, double> get costByType {
    final out = <DamageType, double>{};
    for (final s in surfaces) {
      for (final i in s.assessment.items) {
        final c = i.estimatedCost;
        if (c == null) continue;
        out[i.type] = (out[i.type] ?? 0) + c;
      }
    }
    return out;
  }

  /// Số hạng mục chưa có đơn giá (tổng tiền đang thiếu phần này).
  int get unpricedItems =>
      surfaces.fold(0, (s, e) => s + e.assessment.unpricedCount);

  bool get usesSampleRates => surfaces.any((s) => s.assessment.usesSampleRates);

  /// Theo tòa nhà, tiền nhiều trước.
  List<CostGroup> get byBuilding =>
      _group((s) => s.building, (s) => null)
        ..sort((a, b) => b.cost.compareTo(a.cost));

  /// Theo phòng (trong tòa), ưu tiên mức nặng rồi tiền nhiều.
  List<CostGroup> get byRoom =>
      _group((s) => '${s.building}\u0000${s.room}', (s) => s.building)
        ..sort((a, b) {
          final w = (b.worst?.index ?? -1).compareTo(a.worst?.index ?? -1);
          return w != 0 ? w : b.cost.compareTo(a.cost);
        });

  List<CostGroup> _group(
    String Function(AssessedSurface) key,
    String? Function(AssessedSurface) building,
  ) {
    final groups = <String, List<AssessedSurface>>{};
    for (final s in surfaces) {
      (groups[key(s)] ??= []).add(s);
    }
    return [
      for (final MapEntry(key: k, value: items) in groups.entries)
        CostGroup(
          name: k.contains('\u0000') ? k.split('\u0000').last : k,
          building: building(items.first),
          surfaces: items.length,
          cost: items.fold(0, (s, e) => s + e.cost),
          averageScore:
              items.fold<double>(0, (s, e) => s + e.score) / items.length,
          worst: _worstOf(items),
        ),
    ];
  }

  static DamageSeverity? _worstOf(List<AssessedSurface> items) {
    DamageSeverity? w;
    for (final s in items) {
      final v = s.worst;
      if (v != null && (w == null || v.index > w.index)) w = v;
    }
    return w;
  }

  static int _priority(AssessedSurface a, AssessedSurface b) {
    final w = (b.worst?.index ?? -1).compareTo(a.worst?.index ?? -1);
    if (w != 0) return w;
    final c = b.cost.compareTo(a.cost);
    if (c != 0) return c;
    return a.score.compareTo(b.score);
  }
}
