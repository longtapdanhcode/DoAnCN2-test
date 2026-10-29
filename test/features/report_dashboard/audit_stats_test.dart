import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/domain/audit_stats.dart';

final _now = DateTime(2026, 10, 26, 14);

AssetModel _asset(
  String code, {
  String? area,
  int quantity = 1,
  String status = 'good',
  DateTime? lastAuditAt,
}) => AssetModel(code)
  ..name = code
  ..area = area
  ..quantity = quantity
  ..status = status
  ..lastAuditAt = lastAuditAt;

AuditRecordModel _record(String code, int quantity, DateTime at) =>
    AuditRecordModel(0)
      ..scanCode = code
      ..quantity = quantity
      ..timestamp = at;

void main() {
  test('Empty catalog gives zeros and no areas', () {
    final stats = AuditStats.compute(assets: [], records: [], now: _now);
    expect(stats.totalAssets, 0);
    expect(stats.progress, 0);
    expect(stats.areas, isEmpty);
    expect(stats.periodLabel, 'Tháng 10/2026');
  });

  test('Counts audits in the current month only', () {
    final stats = AuditStats.compute(
      assets: [
        // Kiểm kê trong tháng (theo lastAuditAt).
        _asset('A', area: 'Kho', lastAuditAt: DateTime(2026, 10, 3)),
        // Kiểm kê tháng trước: chưa tính là đã kiểm kỳ này.
        _asset('B', area: 'Kho', lastAuditAt: DateTime(2026, 9, 30)),
        // Có phiếu trong tháng (mã viết thường vẫn khớp).
        _asset('C', area: 'Xưởng'),
        _asset('D', area: 'Xưởng', status: 'damaged'),
        _asset('E', status: 'check'),
      ],
      records: [
        _record('c', 1, DateTime(2026, 10, 26, 9)),
        _record('B', 1, DateTime(2026, 9, 29)),
      ],
      now: _now,
    );

    expect(stats.totalAssets, 5);
    expect(stats.auditedAssets, 2);
    expect(stats.notAudited, 3);
    expect(stats.needsCheck, 2);
    expect(stats.damaged, 1);
    expect(stats.auditsToday, 1);
    expect(stats.auditsInPeriod, 1);
    expect(stats.progress, closeTo(0.4, 1e-9));
  });

  test('Groups progress and discrepancies by area', () {
    final stats = AuditStats.compute(
      assets: [
        _asset('P1', area: 'Kho trung tâm', quantity: 12),
        _asset('P2', area: 'Kho trung tâm', quantity: 4),
        _asset('M1', area: 'Xưởng sản xuất A', quantity: 8),
        _asset('X1'),
      ],
      records: [
        _record('P1', 11, DateTime(2026, 10, 20)), // sai lệch
        _record('P2', 4, DateTime(2026, 10, 21)), // khớp
        _record('M1', 8, DateTime(2026, 10, 22)), // khớp
        _record(
          'UNKNOWN',
          3,
          DateTime(2026, 10, 22),
        ), // không có trong danh mục
      ],
      now: _now,
    );

    expect(stats.discrepancies, 1);
    expect(stats.matched, 2);
    final byName = {for (final a in stats.areas) a.name: a};
    expect(byName.keys, [
      'Chưa có khu vực',
      'Kho trung tâm',
      'Xưởng sản xuất A',
    ]);
    expect(byName['Kho trung tâm']!.planned, 2);
    expect(byName['Kho trung tâm']!.done, 2);
    expect(byName['Kho trung tâm']!.discrepancies, 1);
    expect(byName['Xưởng sản xuất A']!.progress, 1);
    expect(byName['Chưa có khu vực']!.done, 0);
  });

  test('Chọn kỳ là tháng trước: chỉ tính phiếu của tháng đó', () {
    final stats = AuditStats.compute(
      assets: [
        _asset('A-1', area: 'Kho'),
        _asset('A-2', area: 'Kho'),
      ],
      records: [
        _record('A-1', 1, DateTime(2026, 9, 15)),
        _record('A-2', 1, DateTime(2026, 10, 20)),
      ],
      now: _now,
      period: DateTime(2026, 9),
    );
    expect(stats.periodLabel, 'Tháng 9/2026');
    expect(stats.auditedAssets, 1);
    expect(stats.auditsInPeriod, 1);
    // "Hôm nay" vẫn tính theo ngày hiện tại, không theo kỳ chọn.
    expect(stats.auditsToday, 0);
  });

  test('availablePeriods: tháng có phiếu + tháng hiện tại, mới nhất trước', () {
    final months = AuditStats.availablePeriods([
      _record('A', 1, DateTime(2026, 8, 3)),
      _record('B', 1, DateTime(2026, 8, 25)),
      _record('C', 1, DateTime(2026, 5, 1)),
    ], _now);
    expect(months, [DateTime(2026, 10), DateTime(2026, 8), DateTime(2026, 5)]);
    expect(AuditStats.labelOf(months.first), 'Tháng 10/2026');
  });
}
