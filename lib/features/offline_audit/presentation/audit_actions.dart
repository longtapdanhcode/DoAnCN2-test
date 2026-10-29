import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';

import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/evidence_photo_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/domain/audit_stats.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/controllers/audit_stats_provider.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/sync_controller.dart';

/// Kích hoạt đồng bộ dữ liệu ngoại tuyến lên Supabase Cloud.
Future<void> triggerSync(BuildContext context, WidgetRef ref) async {
  final syncState = ref.read(syncControllerProvider);
  if (syncState.isLoading) return;

  // Không thử gọi Supabase khi thiết bị không có mạng; phiếu vẫn nằm trên máy.
  if (!checkOnline(ref)) {
    showFlSnack(
      context,
      'Thiết bị đang ngoại tuyến. Phiếu vẫn được lưu trên máy và sẽ đồng bộ khi có mạng.',
      tone: FlTone.warning,
    );
    return;
  }

  try {
    final count = await ref.read(syncControllerProvider.notifier).syncAll();
    final audits = count == 0
        ? 'Không có phiếu nào cần đồng bộ.'
        : 'Đã đồng bộ $count phiếu lên đám mây.';

    // Danh mục tài sản đồng bộ riêng: lỗi ở đây không làm hỏng kết quả phiếu.
    String catalog;
    var catalogOk = true;
    try {
      final result = await ref.read(assetCatalogRepositoryProvider).sync();
      catalog = ' Danh mục: ${result.pulled} tài sản.';
      if (result.conflicts > 0) {
        catalogOk = false;
        catalog += ' ${result.conflicts} tài sản khác phiên bản cần đối chiếu.';
      }
    } catch (e) {
      debugPrint('[Sync] Lỗi đồng bộ danh mục tài sản: $e');
      catalogOk = false;
      catalog = ' Chưa tải được danh mục tài sản, vui lòng thử lại.';
    }

    if (context.mounted) {
      showFlSnack(
        context,
        '$audits$catalog',
        tone: catalogOk ? FlTone.success : FlTone.warning,
      );
    }
  } catch (e) {
    debugPrint('[Sync] Lỗi đồng bộ phiếu kiểm kê: $e');
    if (context.mounted) {
      showFlSnack(
        context,
        'Chưa đồng bộ được. Dữ liệu vẫn an toàn trên máy, vui lòng thử lại.',
        tone: FlTone.danger,
      );
    }
  }
}

/// Đọc các ảnh minh chứng của [records] để đưa vào PDF.
///
/// Phiếu đọc từ đám mây (bản web) chỉ có đường dẫn chữ ký: tải ảnh chữ ký về
/// [AuditRecordModel.signatureBytes] luôn để PDF vẽ được chữ ký.
Future<Map<String, Uint8List>> loadEvidencePhotos(
  WidgetRef ref,
  List<AuditRecordModel> records,
) async {
  final store = ref.read(evidencePhotoStoreProvider);
  for (final r in records) {
    final url = r.signatureUrl;
    if ((r.signatureBytes?.isEmpty ?? true) &&
        url != null &&
        url.startsWith('http')) {
      final bytes = await store.read(url);
      if (bytes != null) r.signatureBytes = bytes;
    }
  }
  return store.readAll([for (final r in records) ...?r.photoFiles]);
}

/// Xuất báo cáo PDF của kỳ đang chọn và mở hộp thoại chia sẻ hệ thống.
Future<void> exportPdfReport(BuildContext context, WidgetRef ref) async {
  try {
    showFlSnack(context, 'Đang tạo báo cáo PDF...');

    final period = ref.read(reportPeriodProvider);
    final records = ref.read(reportRecordsProvider);
    final bytes = await PdfReportGenerator.generateAuditReport(
      records,
      periodLabel: AuditStats.labelOf(period),
      photoBytes: await loadEvidencePhotos(ref, records),
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'bao_cao_kiem_ke_${period.year}_${period.month.toString().padLeft(2, '0')}.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      showFlSnack(context, 'Lỗi khi xuất PDF: $e', tone: FlTone.danger);
    }
  }
}
