import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';

/// Bản web: tải lại phiếu và danh mục tài sản từ Supabase ngay.
Future<void> refreshCloudData(BuildContext context, WidgetRef ref) async {
  ref.invalidate(auditRecordsProvider);
  try {
    final result = await ref.read(assetCatalogRepositoryProvider).sync();
    final records = await ref.read(auditRecordsProvider.future);
    if (context.mounted) {
      showFlSnack(
        context,
        'Đã tải lại: ${records.length} phiếu, ${result.pulled} tài sản.',
        tone: FlTone.success,
      );
    }
  } catch (e) {
    if (context.mounted) {
      showFlSnack(
        context,
        'Chưa tải được dữ liệu đám mây: $e',
        tone: FlTone.danger,
      );
    }
  }
}
