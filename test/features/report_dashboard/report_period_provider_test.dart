import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/controllers/audit_stats_provider.dart';

AuditRecordModel _record(int id, DateTime at) => AuditRecordModel(id)
  ..scanCode = 'TS-$id'
  ..quantity = 1
  ..signatureBytes = [1]
  ..timestamp = at;

void main() {
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);
  final lastMonth = DateTime(now.year, now.month - 1);

  ProviderContainer container(List<AuditRecordModel> records) {
    final c = ProviderContainer(
      overrides: [finalAuditRecordsProvider.overrideWithValue(records)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('mặc định là tháng hiện tại và chỉ lấy phiếu tháng đó', () {
    final c = container([
      _record(1, now),
      _record(2, lastMonth.add(const Duration(days: 3))),
    ]);
    expect(c.read(reportPeriodProvider), thisMonth);
    expect(c.read(reportRecordsProvider).map((r) => r.id), [1]);
  });

  test('chọn tháng trước thì danh sách phiếu đổi theo', () {
    final c = container([
      _record(1, now),
      _record(2, lastMonth.add(const Duration(days: 3))),
    ]);
    c.read(selectedReportPeriodProvider.notifier).select(lastMonth);
    expect(c.read(reportPeriodProvider), lastMonth);
    expect(c.read(reportRecordsProvider).map((r) => r.id), [2]);
  });

  test('tháng không có trong danh sách thì quay về tháng hiện tại', () {
    final c = container([_record(1, now)]);
    c.read(selectedReportPeriodProvider.notifier).select(DateTime(2020, 1));
    expect(c.read(reportPeriodProvider), thisMonth);
  });
}
