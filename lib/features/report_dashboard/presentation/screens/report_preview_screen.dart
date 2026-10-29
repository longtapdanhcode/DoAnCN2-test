import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/audit_actions.dart';

import '../../domain/audit_stats.dart';
import '../controllers/audit_stats_provider.dart';

/// Xem trước đúng file PDF báo cáo của kỳ đang chọn, cuộn qua mọi trang
/// (gồm chữ ký) trước khi xuất.
class ReportPreviewScreen extends ConsumerWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(reportRecordsProvider);
    final period = ref.watch(reportPeriodProvider);
    final label = AuditStats.labelOf(period);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/reports'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xem trước báo cáo PDF',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$label • ${records.length} phiếu đã ký',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FlColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => exportPdfReport(context, ref),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Xuất'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              // Tạo lại khi đổi kỳ hoặc dữ liệu phiếu thay đổi.
              key: ValueKey('$label-${records.length}'),
              build: (_) async => PdfReportGenerator.generateAuditReport(
                records,
                periodLabel: label,
                photoBytes: await loadEvidencePhotos(ref, records),
              ),
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              maxPageWidth: 700,
              loadingWidget: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang tạo báo cáo PDF kèm chữ ký và ảnh minh chứng…',
                    style: TextStyle(fontSize: 13, color: FlColors.muted),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bản web có thể mất vài chục giây khi phiếu có ảnh.',
                    style: TextStyle(fontSize: 12, color: FlColors.muted),
                  ),
                ],
              ),
              onError: (context, error) =>
                  Center(child: Text('Không dựng được bản xem trước: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
