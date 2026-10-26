import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
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
