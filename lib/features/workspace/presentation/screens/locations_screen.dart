import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/domain/audit_stats.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/controllers/audit_stats_provider.dart';

import '../../data/workspace_settings.dart';
import '../../domain/area_summary.dart';
import '../workspace_page.dart';

/// Màn Địa điểm (Card 27): các khu vực của nơi đang kiểm kê, tiến độ kỳ này
/// và các vị trí bên trong. Chạm một khu vực để xem tài sản của khu vực đó.
class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceProvider);
    final stats = ref.watch(auditStatsProvider);
    final assets = ref.watch(assetsProvider).value ?? const [];
    final areas = buildAreaSummaries(assets, stats.areas);
    final desktop = ResponsiveLayout.isDesktop(context);

    final overview = FlCard(
      child: Row(
        children: [
          const IconTile(icon: Icons.factory_outlined),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspace.siteName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  '${workspace.shift} • ${areas.length} khu vực • '
                  '${stats.totalAssets} tài sản • '
                  'kỳ ${AuditStats.labelOf(stats.periodStart)}',
                  style: const TextStyle(fontSize: 12, color: FlColors.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/settings'),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );

    final cards = [for (final a in areas) _AreaCard(area: a)];

    return WorkspacePage(
      title: 'Địa điểm',
      subtitle: 'Khu vực và vị trí kiểm kê theo danh mục tài sản.',
      children: [
        overview,
        const Gap(20),
        if (areas.isEmpty)
          const InfoBanner(
            icon: Icons.info_outline_rounded,
            tone: FlTone.info,
            title: 'Chưa có khu vực nào',
            subtitle: 'Khu vực lấy từ danh mục tài sản. Thêm tài sản kèm khu vực ở màn Tài sản.',
          )
        else if (desktop)
          FlGrid(columns: 2, spacing: 20, children: cards)
        else
          for (final c in cards) ...[c, const Gap(14)],
      ],
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});

  final AreaSummary area;

  @override
  Widget build(BuildContext context) {
    final p = area.progress;
    final shown = area.positions.take(4).toList();
    final more = area.positions.length - shown.length;
    final filter = area.filterArea;

    return FlCard(
      onTap: () => context.go(
        filter == null
            ? '/assets'
            : Uri(
                path: '/assets',
                queryParameters: {'area': filter},
              ).toString(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: FlColors.primary),
              const Gap(10),
              Expanded(
                child: Text(
                  area.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(p.progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: FlColors.primary,
                ),
              ),
            ],
          ),
          const Gap(12),
          FlProgressBar(value: p.progress),
          const Gap(8),
          Text(
            'Đã kiểm ${p.done}/${p.planned} tài sản',
            style: const TextStyle(fontSize: 12, color: FlColors.muted),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (area.needsAttention > 0)
                StatusPill(
                  label: '${area.needsAttention} cần xử lý',
                  tone: FlTone.warning,
                ),
              if (p.discrepancies > 0)
                StatusPill(
                  label: '${p.discrepancies} sai lệch số lượng',
                  tone: FlTone.danger,
                ),
              if (area.needsAttention == 0 && p.discrepancies == 0)
                const StatusPill(label: 'Không có vấn đề'),
            ],
          ),
          const Gap(14),
          const Divider(height: 1),
          const Gap(10),
          for (final pos in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(pos.name, style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                    '${pos.assets} tài sản',
                    style: const TextStyle(fontSize: 12, color: FlColors.muted),
                  ),
                ],
              ),
            ),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'và $more vị trí khác',
                style: const TextStyle(fontSize: 12, color: FlColors.muted),
              ),
            ),
          const Gap(6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Xem tài sản  ›',
              style: TextStyle(
                fontSize: 12,
                color: FlColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
