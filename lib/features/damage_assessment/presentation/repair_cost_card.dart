import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

import '../domain/entities/damage_enums.dart';
import '../domain/repair_cost_summary.dart';
import 'damage_format.dart';

/// Màu theo mức hư hỏng, dùng chung cho thẻ và danh sách.
FlTone severityTone(DamageSeverity? s) => switch (s) {
  null => FlTone.success,
  DamageSeverity.light => FlTone.info,
  DamageSeverity.moderate => FlTone.warning,
  DamageSeverity.severe => FlTone.danger,
};

/// Thẻ "Chi phí sửa chữa ước tính": tổng tiền, điểm cơ sở vật chất, số bề
/// mặt theo mức và các phòng cần ưu tiên.
class RepairCostCard extends StatelessWidget {
  const RepairCostCard({
    super.key,
    required this.summary,
    this.subtitle,
    this.maxRooms = 5,
    this.compact = false,
  });

  final RepairCostSummary summary;
  final String? subtitle;
  final int maxRooms;

  /// Bố cục điện thoại: chỉ số xếp dọc.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final score = s.facilityScore;
    final rooms = s.byRoom.where((r) => r.cost > 0 || r.worst != null);

    final headline = [
      _Metric(
        label: 'Chi phí ước tính',
        value: formatVnd(s.totalCost),
        color: FlColors.primary,
        valueKey: const Key('repair-total'),
      ),
      _Metric(
        label: 'Điểm cơ sở vật chất',
        value: score == null ? '—' : '${score.round()}/100',
        color: score == null
            ? FlColors.muted
            : score >= 80
            ? FlColors.primary
            : score >= 60
            ? FlColors.warning
            : FlColors.danger,
      ),
      _Metric(label: 'Bề mặt đã đánh giá', value: '${s.count}'),
    ];

    return FlCard(
      key: const Key('repair-cost-card'),
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            title: 'Chi phí sửa chữa ước tính',
            subtitle: subtitle ?? 'Theo phiếu đánh giá hư hỏng bề mặt đã ký',
          ),
          const Gap(14),
          if (s.isEmpty)
            const Text(
              'Chưa có phiếu nào đánh giá hư hỏng bề mặt. Quét thẻ QR trên '
              'tường, trần… rồi lập phiếu để có chi phí.',
              style: TextStyle(fontSize: 13, color: FlColors.muted),
            )
          else ...[
            if (compact)
              Wrap(spacing: 24, runSpacing: 12, children: headline)
            else
              Row(
                children: [
                  for (final (i, m) in headline.indexed) ...[
                    if (i > 0) const Gap(24),
                    Expanded(child: m),
                  ],
                ],
              ),
            const Gap(14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sev in DamageSeverity.values.reversed)
                  StatusPill(
                    label: '${sev.label}: ${s.countWorst(sev)}',
                    tone: severityTone(sev),
                  ),
              ],
            ),
            if (rooms.isNotEmpty) ...[
              const Gap(16),
              const SectionLabel('Phòng cần ưu tiên'),
              const Gap(8),
              for (final r in rooms.take(maxRooms))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${r.building} · ${r.surfaces} bề mặt · '
                              'điểm ${r.averageScore.round()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: FlColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.worst != null) ...[
                        StatusPill(
                          label: r.worst!.label,
                          tone: severityTone(r.worst),
                        ),
                        const Gap(10),
                      ],
                      Text(
                        formatVnd(r.cost),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
            if (s.unpricedItems > 0 || s.usesSampleRates) ...[
              const Gap(10),
              if (s.unpricedItems > 0)
                Text(
                  '${s.unpricedItems} hạng mục chưa có đơn giá, chưa tính vào tổng.',
                  style: const TextStyle(fontSize: 12, color: FlColors.warning),
                ),
              if (s.usesSampleRates)
                const Text(
                  'Có phiếu tính theo bảng giá minh hoạ, chưa phải giá thật của nhà trường.',
                  style: TextStyle(fontSize: 12, color: FlColors.warning),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.color = FlColors.ink,
    this.valueKey,
  });

  final String label;
  final String value;
  final Color color;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: FlColors.muted)),
      const Gap(4),
      Text(
        value,
        key: valueKey,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}
