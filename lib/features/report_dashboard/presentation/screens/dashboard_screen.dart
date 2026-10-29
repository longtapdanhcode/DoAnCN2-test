import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_form_controller.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';

import '../../domain/audit_stats.dart';
import '../controllers/audit_stats_provider.dart';

/// Màn hình Tổng quan hiện trường (Figma 01 / M01).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileDashboard(),
      desktopBody: DesktopDashboard(),
    );
  }
}

/// Mã phiếu hiển thị cho một bản ghi Isar.
String auditCode(AuditRecordModel r) =>
    'KK-${(r.timestamp ?? DateTime.now()).year}-${r.id.toString().padLeft(3, '0')}';

/// Tên hiển thị của bản ghi: tên tài sản, rồi nhãn AI, cuối cùng là mã quét.
String auditTitle(AuditRecordModel r) =>
    r.assetName ?? r.aiDetectedLabel ?? r.scanCode ?? 'Không có mã';

/// Mở lại bản nháp để ký xác nhận và hoàn tất (cập nhật chính phiếu đó).
void resumeDraft(BuildContext context, AuditRecordModel draft) {
  context.push('/audit-form', extra: {'draftId': draft.id});
}

/// Hỏi xác nhận rồi xoá một bản nháp chưa ký khỏi máy.
Future<void> confirmDeleteDraft(
  BuildContext context,
  WidgetRef ref,
  AuditRecordModel draft,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Xoá bản nháp?'),
      content: Text(
        'Bản nháp ${auditCode(draft)} (${auditTitle(draft)}) sẽ bị xoá khỏi '
        'thiết bị và không thể khôi phục.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: FlColors.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Xoá'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final deleted = await ref
      .read(auditFormControllerProvider.notifier)
      .deleteDraft(draft.id);
  if (context.mounted) {
    showFlSnack(
      context,
      deleted ? 'Đã xoá bản nháp.' : 'Không xoá được bản nháp.',
      tone: deleted ? FlTone.success : FlTone.danger,
    );
  }
}

/// Giao diện Tổng quan cho desktop / web.
class DesktopDashboard extends ConsumerWidget {
  const DesktopDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingSyncCountProvider);
    // Bản nháp luôn hiện đầu danh sách để không bị trôi mất; còn lại là phiếu chính thức.
    final records = [
      ...ref.watch(draftAuditRecordsProvider),
      ...ref.watch(finalAuditRecordsProvider).take(3),
    ];
    final stats = ref.watch(auditStatsProvider);
    final percent = (stats.progress * 100)
        .toStringAsFixed(1)
        .replaceAll('.', ',');

    return DesktopPage(
      heading: DesktopPageHeading(
        title: 'Tổng quan hiện trường',
        subtitle: 'Theo dõi tài sản, tiến độ kiểm kê và các vấn đề cần xử lý hôm nay.',
        action: FilledButton.icon(
          onPressed: () => context.go('/scanner'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tạo phiếu kiểm kê'),
        ),
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _StatCard(
                label: 'Tổng tài sản',
                value: stats.totalAssets,
                caption: '${stats.areas.length} khu vực trong danh mục',
                icon: Icons.inventory_2_outlined,
                tone: FlTone.success,
                onTap: () => context.go('/assets'),
              ),
              _StatCard(
                label: 'Đã kiểm kê',
                value: stats.auditedAssets,
                caption:
                    '$percent% danh mục ${stats.periodLabel.toLowerCase()}',
                icon: Icons.check_rounded,
                tone: FlTone.success,
              ),
              _StatCard(
                label: 'Cần kiểm tra',
                value: stats.needsCheck,
                caption: stats.damaged == 0
                    ? 'Không có tài sản hư hỏng'
                    : '${stats.damaged} tài sản hư hỏng',
                icon: Icons.center_focus_strong_outlined,
                tone: FlTone.warning,
              ),
              _StatCard(
                label: 'Chờ đồng bộ',
                value: pending,
                caption: 'Đã lưu an toàn trên máy',
                icon: Icons.sync_rounded,
                tone: FlTone.info,
                onTap: () => context.go('/sync'),
              ),
            ];
            final perRow = constraints.maxWidth >= 900 ? 4 : 2;
            return FlGrid(columns: perRow, spacing: 16, children: cards);
          },
        ),
        const Gap(16),
        FlSplitRow(
          main: _AreaProgressCard(stats: stats),
          side: const _EdgeAiCard(),
        ),
        const Gap(16),
        FlSplitRow(
          main: _RecentAuditsCard(records: records),
          side: _AttentionCard(stats: stats),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.tone,
    this.onTap,
  });

  final String label;
  final int value;
  final String caption;
  final IconData icon;
  final FlTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: FlColors.muted,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      flNumber(value),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: FlColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              IconTile(icon: icon, tone: tone, size: 40),
            ],
          ),
          const Gap(18),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: tone == FlTone.warning
                  ? FlColors.warningStrong
                  : tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaProgressCard extends StatelessWidget {
  const _AreaProgressCard({required this.stats});

  final AuditStats stats;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            title: 'Tiến độ kiểm kê theo khu vực',
            subtitle: 'Kỳ kiểm kê ${stats.periodLabel.toLowerCase()}',
            trailing: stats.totalAssets > 0 && stats.notAudited == 0
                ? const StatusPill(label: 'Hoàn tất')
                : const StatusPill(label: 'Đang thực hiện', tone: FlTone.info),
          ),
          const Gap(16),
          if (stats.areas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có tài sản trong danh mục. Đồng bộ danh mục ở màn Tài sản.',
                style: TextStyle(fontSize: 13, color: FlColors.muted),
              ),
            ),
          for (final area in stats.areas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      area.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: FlProgressBar(
                      value: area.progress,
                      color: area.progress < 0.5
                          ? const Color(0xFFA9D3CC)
                          : FlColors.primary,
                    ),
                  ),
                  const Gap(20),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${area.done} / ${area.planned}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: FlColors.muted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(area.progress * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EdgeAiCard extends StatelessWidget {
  const _EdgeAiCard();

  @override
  Widget build(BuildContext context) {
    return FlCard(
      padding: const EdgeInsets.all(24),
      // spaceBetween đẩy nút xuống đáy khi thẻ cao bằng cột bên cạnh,
      // và vẫn hợp lệ khi thẻ xếp chồng trong vùng cuộn.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconTile(icon: Icons.center_focus_strong_outlined, size: 44),
                  Spacer(),
                  StatusPill(label: 'ON-DEVICE'),
                ],
              ),
              Gap(18),
              Text(
                'Kiểm kê nhanh với Edge AI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Gap(10),
              Text(
                'Quét mã hoặc nhận diện thiết bị ngay trên máy, kể cả khi không có mạng.',
                style: TextStyle(
                  fontSize: 13,
                  color: FlColors.muted,
                  height: 1.5,
                ),
              ),
              Gap(20),
            ],
          ),
          FilledButton.icon(
            onPressed: () => context.go('/scanner'),
            icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
            label: const Text('Bắt đầu quét thiết bị'),
          ),
        ],
      ),
    );
  }
}

class _RecentAuditsCard extends ConsumerWidget {
  const _RecentAuditsCard({required this.records});

  final List<AuditRecordModel> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlCard(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CardHeader(
              title: 'Phiếu kiểm kê gần đây',
              trailing: TextButton(
                onPressed: () => context.go('/reports'),
                child: const Text('Xem tất cả →'),
              ),
            ),
          ),
          const Gap(12),
          Container(
            color: FlColors.surfaceAlt,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: SectionLabel('Mã phiếu')),
                Expanded(flex: 4, child: SectionLabel('Tài sản')),
                Expanded(flex: 2, child: SectionLabel('Số lượng')),
                Expanded(flex: 3, child: SectionLabel('Trạng thái')),
              ],
            ),
          ),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Text(
                'Chưa có phiếu kiểm kê nào trên máy. Quét thiết bị để tạo phiếu đầu tiên.',
                style: TextStyle(fontSize: 13, color: FlColors.muted),
              ),
            ),
          for (final (i, r) in records.indexed)
            InkWell(
              onTap: r.isDraft ? () => resumeDraft(context, r) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: i == records.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: FlColors.border),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        auditCode(r),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FlColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        auditTitle(r),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r.quantity} thiết bị',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FlColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Flexible(
                            child: StatusPill(
                              label: r.isDraft
                                  ? 'Bản nháp • chưa ký'
                                  : (r.isSynced ? 'Đã đồng bộ' : 'Chờ đồng bộ'),
                              tone: r.isDraft
                                  ? FlTone.neutral
                                  : (r.isSynced
                                        ? FlTone.success
                                        : FlTone.warning),
                            ),
                          ),
                          if (r.isDraft)
                            IconButton(
                              tooltip: 'Xoá bản nháp',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  confirmDeleteDraft(context, ref, r),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: FlColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.stats});

  final AuditStats stats;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'Cần chú ý'),
          const Gap(24),
          _AttentionRow(
            count: stats.damaged,
            title: 'Thiết bị hư hỏng',
            subtitle: 'Ưu tiên kiểm tra trong hôm nay',
            tone: FlTone.danger,
            onTap: () => context.go('/assets'),
          ),
          const Gap(24),
          _AttentionRow(
            count: stats.discrepancies,
            title: 'Sai lệch số lượng',
            subtitle: 'Đối chiếu với danh mục tài sản',
            tone: FlTone.warning,
            onTap: () => context.go('/reports'),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final int count;
  final String title;
  final String subtitle;
  final FlTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FlRadius.control),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(FlRadius.control),
            ),
            child: Text(
              count.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tone == FlTone.warning
                    ? const Color(0xFF9A6B23)
                    : tone.foreground,
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13)),
                const Gap(4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: FlColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Giao diện Tổng quan cho mobile (Figma M01).
class MobileDashboard extends ConsumerWidget {
  const MobileDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(draftAuditRecordsProvider);
    final records = ref.watch(finalAuditRecordsProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    final now = DateTime.now();
    final stats = ref.watch(auditStatsProvider);
    final today = stats.auditsToday;
    const months = [
      'THÁNG 1', 'THÁNG 2', 'THÁNG 3', 'THÁNG 4', 'THÁNG 5', 'THÁNG 6', //
      'THÁNG 7', 'THÁNG 8', 'THÁNG 9', 'THÁNG 10', 'THÁNG 11', 'THÁNG 12',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header tối
        AnnotatedRegion<SystemUiOverlayStyle>(
          // Header tối: chữ và biểu tượng thanh trạng thái màu sáng.
          value: SystemUiOverlayStyle.light,
          child: Container(
            color: FlColors.sidebar,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 22, 24),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FIELDLINE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Gap(8),
                          Text(
                            'Nhà máy Bình An  ·  Ca sáng',
                            style: TextStyle(
                              color: FlColors.sidebarText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: FlColors.logoTile,
                      child: Text(
                        'HA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              const Text(
                'Tổng quan',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const Gap(4),
              Text(
                '${now.day} ${months[now.month - 1]}, ${now.year}',
                style: const TextStyle(fontSize: 12, color: FlColors.muted),
              ),
              const Gap(16),
              FlCard(
                color: FlColors.primarySoft,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                onTap: () => context.go('/sync'),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: FlColors.primary,
                      child: Icon(Icons.check, size: 15, color: Colors.white),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sẵn sàng kiểm kê',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            pending == 0
                                ? 'Dữ liệu đã lưu trên thiết bị'
                                : '$pending phiếu chờ đồng bộ • lưu trên thiết bị',
                            style: const TextStyle(
                              fontSize: 12,
                              color: FlColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              FlGrid(
                columns: 2,
                spacing: 8,
                children: [
                  _MobileStat(
                    label: 'Tài sản',
                    value: stats.totalAssets,
                    tone: FlTone.success,
                  ),
                  _MobileStat(
                    label: 'Đã kiểm',
                    value: stats.auditedAssets,
                    tone: FlTone.success,
                  ),
                  _MobileStat(
                    label: 'Cần xử lý',
                    value: stats.needsCheck,
                    tone: FlTone.warning,
                  ),
                  _MobileStat(
                    label: 'Phiếu hôm nay',
                    value: today,
                    tone: FlTone.info,
                    pad: true,
                  ),
                ],
              ),
              const Gap(16),
              FlCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Bắt đầu tại hiện trường',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(6),
                    const Text(
                      'Quét mã QR hoặc nhận diện thiết bị bằng AI',
                      style: TextStyle(fontSize: 12, color: FlColors.muted),
                    ),
                    const Gap(14),
                    MobilePrimaryButton(
                      label: 'Quét thiết bị',
                      onPressed: () => context.go('/scanner'),
                    ),
                  ],
                ),
              ),
              const Gap(24),
              if (drafts.isNotEmpty) ...[
                const SectionLabel('Bản nháp chờ ký'),
                const Gap(10),
                for (final r in drafts) ...[
                  _MobileRecentAudit(record: r),
                  const Gap(8),
                ],
                const Gap(16),
              ],
              const SectionLabel('Hoạt động gần đây'),
              const Gap(10),
              if (records.isEmpty)
                const FlCard(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có phiếu nào. Phiếu bạn lưu sẽ hiện ở đây.',
                    style: TextStyle(fontSize: 13, color: FlColors.muted),
                  ),
                ),
              for (final r in records.take(3)) ...[
                _MobileRecentAudit(record: r),
                const Gap(8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileStat extends StatelessWidget {
  const _MobileStat({
    required this.label,
    required this.value,
    required this.tone,
    this.pad = false,
  });

  final String label;
  final int value;
  final FlTone tone;
  final bool pad;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: FlColors.muted),
          ),
          const Gap(2),
          Text(
            pad ? value.toString().padLeft(2, '0') : flNumber(value),
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const Gap(4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tone.background,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRecentAudit extends ConsumerWidget {
  const _MobileRecentAudit({required this.record});

  final AuditRecordModel record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = record.timestamp ?? DateTime.now();
    final card = FlCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 21,
            backgroundColor: FlColors.primarySoft,
            child: Text(
              'KK',
              style: TextStyle(
                color: FlColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${auditCode(record)}  ·  ${auditTitle(record)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  record.isDraft
                      ? '${record.quantity} thiết bị  ·  Bản nháp, chạm để ký'
                      : '${record.quantity} thiết bị  ·  ${record.isSynced ? 'Đã đồng bộ' : 'Lưu ngoại tuyến'}',
                  style: const TextStyle(fontSize: 12, color: FlColors.muted),
                ),
                const Gap(4),
                Text(
                  'Cập nhật ${flTime(t)}',
                  style: const TextStyle(fontSize: 11, color: FlColors.primary),
                ),
              ],
            ),
          ),
          if (record.isDraft)
            IconButton(
              tooltip: 'Xoá bản nháp',
              onPressed: () => confirmDeleteDraft(context, ref, record),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: FlColors.muted,
              ),
            ),
        ],
      ),
    );
    if (!record.isDraft) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(FlRadius.card),
      onTap: () => resumeDraft(context, record),
      child: card,
    );
  }
}
