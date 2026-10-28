import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';

import '../../domain/audit_stats.dart';

/// Số liệu kỳ hiện tại, tự tính lại khi danh mục hoặc phiếu thay đổi.
final auditStatsProvider = Provider<AuditStats>((ref) {
  return AuditStats.compute(
    assets: ref.watch(assetsProvider).value ?? const [],
    records: ref.watch(finalAuditRecordsProvider),
    now: DateTime.now(),
  );
});

/// Tháng đang chọn ở màn Báo cáo; `null` nghĩa là tháng hiện tại.
class SelectedReportPeriod extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? month) => state = month;
}

final selectedReportPeriodProvider =
    NotifierProvider<SelectedReportPeriod, DateTime?>(SelectedReportPeriod.new);

/// Các tháng có thể chọn làm kỳ báo cáo (mới nhất trước).
final availableReportPeriodsProvider = Provider<List<DateTime>>((ref) {
  return AuditStats.availablePeriods(
    ref.watch(finalAuditRecordsProvider),
    DateTime.now(),
  );
});

/// Tháng báo cáo đang áp dụng (đã đảm bảo nằm trong danh sách có thể chọn).
final reportPeriodProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final selected = ref.watch(selectedReportPeriodProvider);
  final available = ref.watch(availableReportPeriodsProvider);
  if (selected != null && available.contains(selected)) return selected;
  return DateTime(now.year, now.month);
});

/// Phiếu chính thức thuộc kỳ báo cáo đang chọn (mới nhất trước).
final reportRecordsProvider = Provider<List<AuditRecordModel>>((ref) {
  final period = ref.watch(reportPeriodProvider);
  return ref
      .watch(finalAuditRecordsProvider)
      .where(
        (r) =>
            r.timestamp != null &&
            r.timestamp!.year == period.year &&
            r.timestamp!.month == period.month,
      )
      .toList();
});

/// Số liệu của kỳ báo cáo đang chọn.
final reportStatsProvider = Provider<AuditStats>((ref) {
  return AuditStats.compute(
    assets: ref.watch(assetsProvider).value ?? const [],
    records: ref.watch(finalAuditRecordsProvider),
    now: DateTime.now(),
    period: ref.watch(reportPeriodProvider),
  );
});
