import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

import '../../features/asset_catalog/data/models/asset_model.dart';
import '../../features/asset_catalog/domain/entities/asset_status.dart';
import '../../features/damage_assessment/domain/entities/damage_enums.dart';
import '../../features/damage_assessment/domain/repair_cost_summary.dart';
import '../../features/damage_assessment/presentation/damage_format.dart';
import '../../features/offline_audit/data/models/audit_record_model.dart';
import '../../features/offline_audit/domain/entities/audit_condition.dart';

/// Tiện ích hỗ trợ tạo tệp PDF báo cáo kiểm kê hiện trường.
class PdfReportGenerator {
  const PdfReportGenerator._();

  /// Font Inter đóng gói trong app (có đủ dấu tiếng Việt, không cần mạng).
  /// Chỉ khi không đọc được asset mới dùng Helvetica (không có dấu).
  static Future<(pw.Font, pw.Font)> _loadFonts() async {
    try {
      final regular = await rootBundle.load(
        'assets/fonts/inter/Inter-Regular.ttf',
      );
      final bold = await rootBundle.load('assets/fonts/inter/Inter-Bold.ttf');
      return (pw.Font.ttf(regular), pw.Font.ttf(bold));
    } catch (_) {
      return (pw.Font.helvetica(), pw.Font.helveticaBold());
    }
  }

  /// Tạo PDF "Danh sách tài sản" từ [assets] (thường là danh sách đang lọc).
  static Future<Uint8List> generateAssetList(List<AssetModel> assets) async {
    final pdf = pw.Document();
    final (font, boldFont) = await _loadFonts();
    final date = DateFormat('dd/MM/yyyy');
    final generatedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final totalQuantity = assets.fold<int>(0, (sum, a) => sum + a.quantity);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DANH SÁCH TÀI SẢN',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    color: PdfColors.teal800,
                  ),
                ),
                pw.Text(
                  'Ngày xuất: $generatedAt',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '${assets.length} tài sản • Tổng số lượng: $totalQuantity',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.teal800),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          if (assets.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 40),
              child: pw.Center(
                child: pw.Text(
                  'Không có tài sản nào trong danh sách.',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'STT',
                'Mã tài sản',
                'Tên tài sản',
                'Khu vực',
                'SL',
                'Tình trạng',
                'Kiểm kê gần nhất',
              ],
              data: [
                for (final (i, a) in assets.indexed)
                  [
                    '${i + 1}',
                    a.code,
                    a.name,
                    [a.area, a.location].whereType<String>().join(' • '),
                    '${a.quantity}',
                    AssetStatus.fromCode(a.status).label,
                    a.lastAuditAt == null
                        ? 'Chưa kiểm kê'
                        : date.format(a.lastAuditAt!),
                  ],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.teal800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignments: {0: pw.Alignment.center, 4: pw.Alignment.center},
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Số phiếu hiển thị, thống nhất với màn Tổng quan (ví dụ `KK-2026-001`).
  static String voucherNumber(AuditRecordModel r) =>
      'KK-${(r.timestamp ?? DateTime.now()).year}-${r.id.toString().padLeft(3, '0')}';

  static PdfColor _conditionColor(String? code) =>
      switch (AuditCondition.fromCode(code)) {
        AuditCondition.good => PdfColors.green800,
        AuditCondition.check => PdfColors.orange800,
        AuditCondition.damaged => PdfColors.red800,
        null => PdfColors.grey700,
      };

  /// Tạo PDF báo cáo kiểm kê: thống kê tổng quan, bảng tóm tắt các phiếu, rồi
  /// chi tiết từng phiếu kèm ảnh chữ ký người xác nhận.
  static Future<Uint8List> generateAuditReport(
    List<AuditRecordModel> allRecords, {
    String? periodLabel,

    /// Byte ảnh minh chứng theo tên tệp (do nơi gọi đọc từ máy); ảnh thiếu
    /// hoặc hỏng thì bỏ qua.
    Map<String, Uint8List> photoBytes = const {},
  }) async {
    // Bản nháp (chưa ký) không đưa vào báo cáo.
    final records = allRecords.where((r) => !r.isDraft).toList();
    final pdf = pw.Document();
    final (font, boldFont) = await _loadFonts();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    final dateTime = DateFormat('dd/MM/yyyy HH:mm');
    final generatedAt = dateTime.format(DateTime.now());

    // Phiếu đánh giá bề mặt không có số lượng: không cộng vào tổng.
    bool assessed(AuditRecordModel r) => r.damageAssessmentJson != null;
    final allAssessed = records.isNotEmpty && records.every(assessed);
    final totalQuantity = records
        .where((r) => !assessed(r))
        .fold<int>(0, (sum, r) => sum + r.quantity);
    final distinctAssets = records
        .map((r) => r.scanCode?.trim().toUpperCase())
        .whereType<String>()
        .toSet()
        .length;
    final needAttention = records
        .where((r) => r.condition == 'check' || r.condition == 'damaged')
        .length;
    final pending = records.where((r) => !r.isSynced).length;
    final cost = RepairCostSummary.fromRecords(records);

    const accent = PdfColors.teal800;

    pw.Widget stat(String label, String value, {PdfColor color = accent}) =>
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 3),
                // Số tiền dài thu nhỏ cho vừa ô thay vì xuống dòng.
                pw.FittedBox(
                  fit: pw.BoxFit.scaleDown,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    value,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    pw.Widget sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldFont, fontSize: 12, color: accent),
      ),
    );

    pw.Widget field(String label, String value, {PdfColor? color}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                value,
                style: pw.TextStyle(
                  font: color != null ? boldFont : font,
                  fontSize: 9.5,
                  color: color ?? PdfColors.black,
                ),
              ),
            ],
          ),
        );

    pw.Widget detailCard(AuditRecordModel r) {
      // Chữ ký hỏng không được làm hỏng cả báo cáo: chỉ phiếu đó báo lỗi.
      pw.MemoryImage? signature;
      var signatureUnreadable = false;
      if (r.signatureBytes != null && r.signatureBytes!.isNotEmpty) {
        try {
          signature = pw.MemoryImage(Uint8List.fromList(r.signatureBytes!));
        } catch (_) {
          signatureUnreadable = true;
        }
      }
      // Ảnh minh chứng hiện trường (ảnh lỗi bỏ qua, không làm hỏng báo cáo).
      final photos = <pw.MemoryImage>[];
      for (final name in r.photoFiles ?? const <String>[]) {
        final bytes = photoBytes[name];
        if (bytes == null) continue;
        try {
          photos.add(pw.MemoryImage(bytes));
        } catch (_) {}
      }
      final place = [r.area, r.location].whereType<String>().join(' • ');
      final condition = AuditCondition.fromCode(r.condition);

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(4),
                  topRight: pw.Radius.circular(4),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Phiếu ${voucherNumber(r)}  •  ${r.scanCode ?? '-'}',
                    style: pw.TextStyle(font: boldFont, fontSize: 10),
                  ),
                  pw.Text(
                    r.timestamp != null ? dateTime.format(r.timestamp!) : '-',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        field('Tên tài sản', r.assetName ?? 'Chưa nhập'),
                        field(
                          'Hạng mục (nhận diện AI)',
                          r.aiDetectedLabel ?? 'Không có',
                        ),
                        field('Khu vực • Vị trí', place.isEmpty ? '-' : place),
                        if (r.surfaceAssessment case final a?) ...[
                          field(
                            'Bề mặt',
                            '${a.material.label} • ${formatQuantity(a.surfaceAreaM2, MeasureUnit.squareMeter)}'
                                ' • điểm ${a.conditionScore.round()}/100',
                          ),
                          field(
                            'Hư hỏng (ước tính)',
                            a.items.isEmpty
                                ? 'Không ghi nhận'
                                : [
                                    for (final i in a.items)
                                      '${i.type.label}: ${formatQuantity(i.measuredQuantity, i.type.unit)}'
                                          ' • ${i.severity.label}'
                                          '${i.fullSurface ? ' (xử lý cả bề mặt)' : ''}'
                                          ' • ${i.hasPrice ? formatVnd(i.estimatedCost!) : 'chưa có đơn giá'}',
                                  ].join('\n'),
                          ),
                          field(
                            'Chi phí sửa chữa ước tính',
                            formatVnd(a.totalCost),
                            color: accent,
                          ),
                        ],
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: field(
                                'Số lượng kiểm kê',
                                assessed(r) ? '-' : '${r.quantity}',
                              ),
                            ),
                            pw.Expanded(
                              child: field(
                                'Tình trạng',
                                condition?.label ?? '-',
                                color: _conditionColor(r.condition),
                              ),
                            ),
                            pw.Expanded(
                              child: field(
                                'Đồng bộ',
                                r.isSynced ? 'Đã đồng bộ' : 'Chờ đồng bộ',
                              ),
                            ),
                          ],
                        ),
                        field(
                          'Ghi chú hiện trường',
                          (r.notes == null || r.notes!.isEmpty)
                              ? '-'
                              : r.notes!,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Chữ ký xác nhận',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          height: 64,
                          width: double.infinity,
                          alignment: pw.Alignment.center,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey400,
                              width: 0.5,
                            ),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: signature != null
                              ? pw.Padding(
                                  padding: const pw.EdgeInsets.all(3),
                                  child: pw.Image(
                                    signature,
                                    fit: pw.BoxFit.contain,
                                  ),
                                )
                              : pw.Text(
                                  signatureUnreadable
                                      ? 'Không đọc được chữ ký'
                                      : 'Chưa có chữ ký',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey500,
                                  ),
                                ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          r.signerName ?? '-',
                          style: pw.TextStyle(font: boldFont, fontSize: 9),
                          textAlign: pw.TextAlign.center,
                        ),
                        if (r.signerRole != null)
                          pw.Text(
                            r.signerRole!,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (photos.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Ảnh minh chứng hiện trường (${photos.length})',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        for (final image in photos)
                          pw.Container(
                            width: 150,
                            height: 100,
                            margin: const pw.EdgeInsets.only(right: 8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.grey400,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Image(image, fit: pw.BoxFit.cover),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BÁO CÁO KIỂM KÊ HIỆN TRƯỜNG',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: accent,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      periodLabel == null
                          ? 'Hệ thống Field Inventory Edge AI (Offline-First)'
                          : 'Kỳ báo cáo: $periodLabel  •  Field Inventory Edge AI',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Ngày xuất: $generatedAt',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: accent),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Báo cáo tự động từ Field Inventory Edge AI App',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Trang ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (context) {
          if (records.isEmpty) {
            return [
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 40),
                  child: pw.Text(
                    'Chưa có dữ liệu kiểm kê nào được ghi nhận.',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ),
              ),
            ];
          }

          return [
            pw.Row(
              children: [
                stat('Số phiếu', '${records.length}'),
                pw.SizedBox(width: 8),
                stat('Tài sản khác nhau', '$distinctAssets'),
                pw.SizedBox(width: 8),
                allAssessed
                    ? stat('Chi phí ước tính', formatVnd(cost.totalCost))
                    : stat('Tổng số lượng', '$totalQuantity'),
                pw.SizedBox(width: 8),
                stat(
                  'Cần xử lý',
                  '$needAttention',
                  color: needAttention > 0 ? PdfColors.red800 : accent,
                ),
                pw.SizedBox(width: 8),
                stat(
                  'Chờ đồng bộ',
                  '$pending',
                  color: pending > 0 ? PdfColors.orange800 : accent,
                ),
              ],
            ),
            sectionTitle('1. Tổng hợp các phiếu kiểm kê'),
            pw.TableHelper.fromTextArray(
              headers: const [
                'STT',
                'Số phiếu',
                'Mã thiết bị',
                'Tài sản',
                'Khu vực',
                'Tình trạng',
                'SL',
                'Thời gian',
              ],
              data: [
                for (final (i, r) in records.indexed)
                  [
                    '${i + 1}',
                    voucherNumber(r),
                    r.scanCode ?? '-',
                    _assetCell(r),
                    [r.area, r.location].whereType<String>().join(' • ').isEmpty
                        ? '-'
                        : [r.area, r.location].whereType<String>().join(' • '),
                    AuditCondition.fromCode(r.condition)?.label ?? '-',
                    assessed(r) ? '-' : '${r.quantity}',
                    r.timestamp != null ? dateTime.format(r.timestamp!) : '-',
                  ],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 8.5,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: accent),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignments: {0: pw.Alignment.center, 6: pw.Alignment.center},
              columnWidths: {
                0: const pw.FixedColumnWidth(32),
                1: const pw.FlexColumnWidth(1.3),
                2: const pw.FlexColumnWidth(1.3),
                3: const pw.FlexColumnWidth(1.8),
                4: const pw.FlexColumnWidth(1.6),
                5: const pw.FlexColumnWidth(1.2),
                6: const pw.FixedColumnWidth(26),
                7: const pw.FlexColumnWidth(1.4),
              },
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
            ),
            if (!cost.isEmpty)
              ..._costSection(
                cost,
                sectionTitle: sectionTitle,
                stat: stat,
                boldFont: boldFont,
                accent: accent,
              ),
            sectionTitle(
              '${cost.isEmpty ? 2 : 3}. Chi tiết từng phiếu và chữ ký xác nhận',
            ),
            // Inseparable: thiếu chỗ cuối trang thì cả phiếu sang trang sau,
            // không bị nén thành khung rỗng.
            for (final r in records) pw.Inseparable(child: detailCard(r)),
            pw.SizedBox(height: 6),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Text(
                  allAssessed
                      ? 'TỔNG CHI PHÍ SỬA CHỮA ƯỚC TÍNH: ${formatVnd(cost.totalCost)}'
                      : 'TỔNG SỐ LƯỢNG THIẾT BỊ: $totalQuantity',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: accent,
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Mục "Đánh giá hư hỏng và chi phí sửa chữa": chỉ số tổng, theo tòa nhà và
  /// danh sách bề mặt xếp theo mức ưu tiên sửa.
  static List<pw.Widget> _costSection(
    RepairCostSummary cost, {
    required pw.Widget Function(String) sectionTitle,
    required pw.Widget Function(String, String, {PdfColor color}) stat,
    required pw.Font boldFont,
    required PdfColor accent,
  }) {
    final score = cost.facilityScore;
    final severe = cost.countWorst(DamageSeverity.severe);
    const maxRows = 30;
    pw.Widget table(
      List<String> headers,
      List<List<String>> rows,
      Map<int, pw.TableColumnWidth> widths, {
      Set<int> right = const {},
    }) => pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        font: boldFont,
        fontSize: 8.5,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: accent),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellAlignments: {for (final i in right) i: pw.Alignment.centerRight},
      columnWidths: widths,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    );

    final notes = [
      'Chi phí là ước tính từ số đo trên ảnh (thẻ QR làm thước) và bảng đơn giá; '
          'cần khảo sát lại trước khi lập dự toán.',
      if (cost.usesSampleRates) 'Có phiếu tính theo bảng giá MINH HOẠ, chưa phải giá thật của nhà trường.',
      if (cost.unpricedItems > 0)
        '${cost.unpricedItems} hạng mục chưa có đơn giá, chưa tính vào tổng.',
      if (cost.count > maxRows)
        'Danh sách ưu tiên chỉ in $maxRows/${cost.count} bề mặt đầu tiên.',
    ];

    return [
      sectionTitle('2. Đánh giá hư hỏng và chi phí sửa chữa (ước tính)'),
      pw.Row(
        children: [
          stat('Chi phí ước tính', formatVnd(cost.totalCost)),
          pw.SizedBox(width: 8),
          stat(
            'Điểm cơ sở vật chất',
            score == null ? '-' : '${score.round()}/100',
            color: score != null && score < 60 ? PdfColors.red800 : accent,
          ),
          pw.SizedBox(width: 8),
          stat('Bề mặt đã đánh giá', '${cost.count}'),
          pw.SizedBox(width: 8),
          stat(
            'Bề mặt hư hỏng nặng',
            '$severe',
            color: severe > 0 ? PdfColors.red800 : accent,
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      table(
        const ['Tòa nhà / khu vực', 'Số bề mặt', 'Điểm TB', 'Chi phí ước tính'],
        [
          for (final b in cost.byBuilding)
            [
              b.name,
              '${b.surfaces}',
              '${b.averageScore.round()}',
              formatVnd(b.cost),
            ],
        ],
        {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.6),
        },
        right: {1, 2, 3},
      ),
      pw.SizedBox(height: 10),
      pw.Text(
        'Danh sách bề mặt theo mức ưu tiên sửa chữa',
        style: pw.TextStyle(font: boldFont, fontSize: 10),
      ),
      pw.SizedBox(height: 6),
      table(
        const ['STT', 'Mã', 'Bề mặt', 'Tòa • Phòng', 'Mức', 'Điểm', 'Chi phí'],
        [
          for (final (i, s) in cost.surfaces.take(maxRows).indexed)
            [
              '${i + 1}',
              s.code.isEmpty ? '-' : s.code,
              s.name,
              '${s.building} • ${s.room}',
              s.worst?.label ?? 'Tốt',
              '${s.score.round()}',
              formatVnd(s.cost),
            ],
        ],
        {
          0: const pw.FixedColumnWidth(28),
          1: const pw.FlexColumnWidth(1.3),
          2: const pw.FlexColumnWidth(1.6),
          3: const pw.FlexColumnWidth(2),
          4: const pw.FlexColumnWidth(0.8),
          5: const pw.FlexColumnWidth(0.7),
          6: const pw.FlexColumnWidth(1.4),
        },
        right: {5, 6},
      ),
      pw.SizedBox(height: 6),
      for (final n in notes)
        pw.Text(
          '• $n',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
    ];
  }

  /// Tên tài sản, kèm nhãn AI khi khác tên do kiểm kê viên nhập.
  static String _assetCell(AuditRecordModel record) {
    final name = record.assetName;
    final ai = record.aiDetectedLabel;
    if (name == null) return ai ?? 'Chưa nhận diện';
    if (ai == null || ai == name) return name;
    return '$name\n(AI: $ai)';
  }
}
