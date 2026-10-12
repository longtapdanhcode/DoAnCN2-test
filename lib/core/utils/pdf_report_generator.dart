import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/offline_audit/data/models/audit_record_model.dart';

/// Tiện ích hỗ trợ tạo tệp PDF báo cáo kiểm kê hiện trường.
class PdfReportGenerator {
  const PdfReportGenerator._();

  /// Tạo mảng byte PDF từ danh sách các bản ghi [AuditRecordModel].
  static Future<Uint8List> generateAuditReport(
    List<AuditRecordModel> records,
  ) async {
    final pdf = pw.Document();

    // Nạp Google Font Roboto hỗ trợ đầy đủ ký tự Unicode Tiếng Việt.
    // Nếu thiết bị đang offline hoặc trong môi trường test, tự động fallback về font mặc định.
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final generatedAt = dateFormat.format(DateTime.now());

    // Tính tổng số lượng thiết bị đã kiểm kê
    final totalQuantity = records.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

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
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BÁO CÁO KIỂM KÊ HIỆN TRƯỜNG',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Hệ thống Field Inventory Edge AI (Offline-First)',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Ngày xuất: $generatedAt',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Tổng mục: ${records.length}',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 10,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.5, color: PdfColors.blue800),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Báo cáo tự động từ Field Inventory Edge AI App',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Trang ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        build: (context) {
          final headers = [
            'STT',
            'Mã thiết bị',
            'Kết quả AI',
            'Số lượng',
            'Thời gian',
          ];

          final data = List.generate(records.length, (index) {
            final record = records[index];
            final timeStr = record.timestamp != null
                ? dateFormat.format(record.timestamp!)
                : '-';

            return [
              '${index + 1}',
              record.scanCode ?? '-',
              record.aiDetectedLabel ?? 'Chưa nhận diện',
              '${record.quantity}',
              timeStr,
            ];
          });

          return [
            if (records.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 40),
                  child: pw.Text(
                    'Chưa có dữ liệu kiểm kê nào được ghi nhận.',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              )
            else ...[
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellStyle: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
                headerAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Text(
                      'TỔNG SỐ LƯỢNG THIẾT BỊ: $totalQuantity',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 11,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }
}
