import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:field_inventory_edge_ai/core/ai_pipeline/ai_config.dart';
import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_measurer.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/presentation/damage_format.dart';

/// Kết quả đo hư hỏng trên khung quét được mã, hiện trước khi lập phiếu.
class MeasurementCard extends StatelessWidget {
  const MeasurementCard({
    super.key,
    required this.measurement,
    required this.isMeasuring,
  });

  final FrameMeasurement? measurement;
  final bool isMeasuring;

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    return FlCard(
      key: const Key('measurement-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('Đo hư hỏng bề mặt')),
              if (m != null)
                StatusPill(
                  label: m.hasScale ? 'Có thước đo QR' : 'Chưa có thước đo',
                  tone: m.hasScale ? FlTone.success : FlTone.warning,
                ),
            ],
          ),
          const Gap(10),
          if (isMeasuring)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                Gap(10),
                Text('Đang đo trên khung vừa quét…'),
              ],
            )
          else if (m == null)
            const Text(
              'Không có ảnh để đo. Bạn vẫn nhập số đo được trên phiếu.',
              style: TextStyle(fontSize: 13, color: FlColors.muted),
            )
          else ...[
            if (m.isEmpty)
              const Text(
                'AI không thấy hư hỏng trong khung xanh.',
                style: TextStyle(fontSize: 13, color: FlColors.muted),
              )
            else
              for (final d in m.measurements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.type.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        m.hasScale
                            ? formatQuantity(d.quantity, d.type.unit)
                            : 'cần nhập số đo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: m.hasScale ? FlColors.ink : FlColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            const Gap(4),
            Text(
              m.hasScale
                  ? 'Vùng AI nhìn thấy ≈ ${formatQuantity(m.capturedAreaM2 ?? 0, MeasureUnit.squareMeter)}. '
                        'Số đo ước lượng theo khung, sửa được trên phiếu.'
                  : 'Thẻ QR quá nhỏ hoặc không rõ trong ảnh. Dán thẻ '
                        '${formatDecimal(AiConfig.markerSizeCm)} cm trên bề mặt và chụp gần hơn để tự đo.',
              style: const TextStyle(fontSize: 12, color: FlColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
