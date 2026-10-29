import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

import '../../domain/entities/vision_analysis.dart';
import '../controllers/scanner_controller.dart';

String _pct(double v) =>
    '${(v * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

/// Một câu kết luận vì sao AI chưa ra kết quả, hoặc `null` khi mọi thứ ổn.
String? aiDiagnosticVerdict(AiDiagnostics d) {
  switch (d.modelStatus) {
    case VisionModelStatus.notLoaded:
      return 'Mô hình chưa được nạp.';
    case VisionModelStatus.missing:
      return 'Tệp mô hình trống, AI đang tắt.';
    case VisionModelStatus.failed:
      return 'Nạp mô hình lỗi: ${d.modelError ?? 'không rõ'}';
    case VisionModelStatus.loaded:
      break;
  }
  if (d.framesReceived == 0) {
    return 'Chưa nhận được khung hình nào từ camera.';
  }
  if (d.framesWithoutImage == d.framesReceived) {
    return 'Camera gửi khung nhưng không kèm ảnh, AI không có gì để phân tích.';
  }
  final last = d.last;
  if (last == null) return 'Đang chờ khung đầu tiên được phân tích.';
  if (last.frameWidth > last.frameHeight) {
    return 'Ảnh vào đang nằm ngang (${last.frameWidth}×${last.frameHeight}), '
        'có thể bị xoay so với lúc huấn luyện.';
  }
  if (last.topLabel == null) return 'Mô hình không trả về điểm nào.';
  if (!last.topPassed) {
    return 'AI đang chạy, điểm cao nhất ${last.topLabel} ${_pct(last.topScore)} '
        'chưa tới ngưỡng ${_pct(last.topThreshold)}.';
  }
  return null;
}

/// Thẻ "Chẩn đoán AI" ở màn Quét: mô hình, số khung, khung gần nhất và
/// kết quả cao nhất kể cả khi dưới ngưỡng.
class AiDiagnosticsPanel extends StatelessWidget {
  const AiDiagnosticsPanel({super.key, required this.diagnostics});

  final AiDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final d = diagnostics;
    final last = d.last;
    final verdict = aiDiagnosticVerdict(d);

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: FlColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? FlColors.ink,
              ),
            ),
          ),
        ],
      ),
    );

    return FlCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('Chẩn đoán AI')),
              StatusPill(
                label: d.modelStatus.label,
                tone: d.modelStatus == VisionModelStatus.loaded
                    ? FlTone.success
                    : FlTone.danger,
              ),
            ],
          ),
          const Gap(10),
          row(
            'Mô hình',
            d.modelStatus == VisionModelStatus.loaded
                ? '${d.labelCount} nhãn'
                : (d.modelError ?? d.modelStatus.label),
          ),
          row(
            'Khung hình',
            'nhận ${d.framesReceived} • phân tích ${d.framesAnalyzed}'
                '${d.framesSkipped > 0 ? ' • bỏ ${d.framesSkipped} (AI bận)' : ''}'
                '${d.framesWithoutImage > 0 ? ' • ${d.framesWithoutImage} không có ảnh' : ''}',
          ),
          if (last != null) ...[
            row(
              'Khung gần nhất',
              last.frameWidth == 0
                  ? 'không giải mã được'
                  : '${last.frameWidth}×${last.frameHeight} '
                        '(${last.frameWidth > last.frameHeight ? 'ngang' : 'dọc'})'
                        ' • ${last.elapsed.inMilliseconds} ms',
            ),
            row(
              'Điểm cao nhất',
              last.topLabel == null
                  ? '—'
                  : '${last.topLabel} ${_pct(last.topScore)} '
                        '(ngưỡng ${_pct(last.topThreshold)})',
              color: last.topPassed ? FlColors.primary : FlColors.warning,
            ),
          ],
          if (verdict != null) ...[
            const Gap(8),
            Text(
              verdict,
              style: const TextStyle(
                fontSize: 12,
                color: FlColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
