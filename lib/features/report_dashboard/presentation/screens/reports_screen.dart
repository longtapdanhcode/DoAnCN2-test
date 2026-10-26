import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/audit_actions.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';

import '../../domain/audit_stats.dart';
import '../controllers/audit_stats_provider.dart';
import 'dashboard_screen.dart' show auditCode, auditTitle;

/// Màn hình Báo cáo kiểm kê (Figma 06 / M07).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _area;

  @override
  Widget build(BuildContext context) {
    // Báo cáo chỉ gồm phiếu chính thức (đã ký); bản nháp không hiện ở đây.
    final records = ref.watch(finalAuditRecordsProvider);
    return ResponsiveLayout.isDesktop(context)
        ? _buildDesktop(records)
        : _buildMobile(records);
  }

  Widget _buildDesktop(List<AuditRecordModel> records) {
    final now = DateTime.now();
    final stats = ref.watch(auditStatsProvider);
    final period = stats.periodLabel;
    final areas = _area == null
        ? stats.areas
        : stats.areas.where((a) => a.name == _area).toList();

    final filterCard = FlCard(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: _Labeled(
              label: 'Kỳ báo cáo',
              child: DropdownButtonFormField<String>(
                initialValue: period,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: [DropdownMenuItem(value: period, child: Text(period))],
                onChanged: (_) {},
              ),
            ),
          ),
          const Gap(20),
          Expanded(
            flex: 4,
            child: _Labeled(
              label: 'Khu vực',
              child: DropdownButtonFormField<String?>(
                initialValue: _area,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tất cả khu vực'),
                  ),
                  for (final a in stats.areas)
                    DropdownMenuItem(value: a.name, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _area = v),
              ),
            ),
          ),
          const Spacer(flex: 4),
          FilledButton(
            onPressed: () => showFlSnack(context, 'Đã áp dụng bộ lọc $period.'),
            child: const Text('Áp dụng bộ lọc'),
          ),
        ],
      ),
    );

    final listCard = FlCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(title: 'Danh sách báo cáo'),
          const Gap(20),
          FlCard(
            color: FlColors.primarySoft,
            borderColor: FlColors.primary.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: FlColors.primary,
                    ),
                    const Gap(12),
                    Text(
                      'Kiểm kê tháng ${now.month}/${now.year}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FlColors.primary,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Text(
                  '${flNumber(stats.auditedAssets)} / ${flNumber(stats.totalAssets)} tài sản đã kiểm kê',
                  style: const TextStyle(fontSize: 12, color: FlColors.muted),
                ),
                const Gap(10),
                Text(
                  'Cập nhật hôm nay • ${flTime(now)}',
                  style: const TextStyle(fontSize: 11, color: FlColors.primary),
                ),
              ],
            ),
          ),
          const Gap(8),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Chưa có phiếu nào để lập biên bản.',
                style: TextStyle(fontSize: 13, color: FlColors.muted),
              ),
            ),
          for (final r in records.take(4)) _ReportListItem(record: r),
        ],
      ),
    );

    final previewCard = FlCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            title: 'Xem trước biên bản',
            trailing: StatusPill(label: 'Xem trước • A4', tone: FlTone.neutral),
          ),
          const Gap(18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 24),
            decoration: BoxDecoration(
              color: FlColors.track,
              borderRadius: BorderRadius.circular(FlRadius.control),
            ),
            child: _ReportPaper(
              areas: areas,
              period: period,
              scope: _area ?? 'Toàn bộ nhà máy',
            ),
          ),
        ],
      ),
    );

    return DesktopPage(
      heading: DesktopPageHeading(
        title: 'Báo cáo kiểm kê',
        subtitle:
            'Tổng hợp kết quả, kiểm tra sai lệch và xuất biên bản có chữ ký.',
        action: FilledButton.icon(
          onPressed: () => exportPdfReport(context, ref),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Xuất báo cáo PDF'),
        ),
      ),
      children: [
        filterCard,
        const Gap(24),
        FlSplitRow(main: listCard, side: previewCard, flex: 4),
      ],
    );
  }

  Widget _buildMobile(List<AuditRecordModel> records) {
    final pending = ref.watch(pendingSyncCountProvider);
    final stats = ref.watch(auditStatsProvider);
    final progress = stats.progress;

    return MobilePage(
      title: 'Báo cáo kiểm kê',
      subtitle: 'Tổng hợp kết quả kiểm kê hiện trường',
      bottomAction: MobilePrimaryButton(
        label: 'Xuất báo cáo PDF',
        onPressed: () => exportPdfReport(context, ref),
      ),
      children: [
        FlCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Tiến độ đợt kiểm kê'),
              const Gap(8),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: FlColors.primary,
                  height: 1.1,
                ),
              ),
              const Gap(6),
              Text(
                '${flNumber(stats.auditedAssets)} / ${flNumber(stats.totalAssets)} tài sản đã kiểm',
                style: const TextStyle(fontSize: 13, color: FlColors.muted),
              ),
              const Gap(14),
              FlProgressBar(value: progress, height: 9),
              const Gap(14),
              Text(
                stats.notAudited == 0
                    ? 'Đã kiểm kê hết danh mục ${stats.periodLabel.toLowerCase()}'
                    : 'Còn ${flNumber(stats.notAudited)} tài sản cần kiểm kê',
                style: const TextStyle(fontSize: 12, color: FlColors.primary),
              ),
            ],
          ),
        ),
        const Gap(22),
        const SectionLabel('Kết quả theo trạng thái'),
        const Gap(10),
        FlGrid(
          columns: 3,
          spacing: 12,
          children: [
            _MetricTile(
              count: stats.matched,
              label: 'Đã khớp',
              tone: FlTone.success,
            ),
            _MetricTile(
              count: stats.discrepancies,
              label: 'Sai lệch',
              tone: FlTone.warning,
            ),
            _MetricTile(
              count: stats.notAudited,
              label: 'Chưa kiểm',
              tone: FlTone.info,
            ),
          ],
        ),
        const Gap(22),
        const SectionLabel('Phiếu gần đây'),
        const Gap(10),
        FlCard(
          padding: const EdgeInsets.all(13),
          onTap: () => context.go('/sync'),
          child: Row(
            children: [
              const IconTile(
                icon: Icons.sync_rounded,
                tone: FlTone.info,
                circle: true,
              ),
              const Gap(10),
              const Expanded(
                child: Text(
                  'Đồng bộ dữ liệu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              StatusPill(
                label: pending == 0 ? 'Đã đồng bộ' : '$pending chờ',
                tone: pending == 0 ? FlTone.success : FlTone.warning,
              ),
              const Icon(Icons.chevron_right_rounded, color: FlColors.muted),
            ],
          ),
        ),
        const Gap(8),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Chưa có phiếu kiểm kê trên máy.',
              style: TextStyle(fontSize: 13, color: FlColors.muted),
            ),
          ),
        for (final r in records.take(5)) ...[
          FlCard(
            padding: const EdgeInsets.all(13),
            onTap: () => exportPdfReport(context, ref),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: FlColors.neutralSoft,
                  child: Text(
                    'PDF',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: FlColors.muted,
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${auditCode(r)}  ·  ${auditTitle(r)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        '${flDate(r.timestamp ?? DateTime.now())}  ·  ${r.quantity} thiết bị',
                        style: const TextStyle(
                          fontSize: 12,
                          color: FlColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: FlColors.muted),
              ],
            ),
          ),
          const Gap(8),
        ],
        const Gap(6),
        const Text(
          'Bản PDF gồm danh sách, ảnh minh chứng và chữ ký xác nhận.',
          style: TextStyle(fontSize: 12, color: FlColors.muted),
        ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: FlColors.muted),
        ),
        const Gap(8),
        child,
      ],
    );
  }
}

class _ReportListItem extends StatelessWidget {
  const _ReportListItem({required this.record});

  final AuditRecordModel record;

  @override
  Widget build(BuildContext context) {
    final signed = record.signatureBytes?.isNotEmpty ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FlColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 18,
                color: FlColors.muted,
              ),
              const Gap(12),
              Text(
                'Phiếu ${auditCode(record)}',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          const Gap(10),
          Text(
            '${auditTitle(record)} • ${record.quantity} thiết bị',
            style: const TextStyle(fontSize: 12, color: FlColors.muted),
          ),
          const Gap(8),
          Text(
            !signed
                ? 'PDF • Chưa có chữ ký'
                : record.signerName != null
                ? 'PDF • Ký bởi ${record.signerName}'
                : 'PDF • Có chữ ký xác nhận',
            style: const TextStyle(fontSize: 11, color: FlColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Trang giấy A4 xem trước biên bản kiểm kê.
class _ReportPaper extends StatelessWidget {
  const _ReportPaper({
    required this.areas,
    required this.period,
    required this.scope,
  });

  final List<AreaProgress> areas;
  final String period;
  final String scope;

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 10, color: FlColors.muted);
    const cell = TextStyle(fontSize: 10, color: FlColors.ink);
    final planned = areas.fold(0, (s, a) => s + a.planned);
    final done = areas.fold(0, (s, a) => s + a.done);
    final diff = areas.fold(0, (s, a) => s + a.discrepancies);

    Widget row(List<Widget> cells, {Color? color, bool divider = true}) =>
        Container(
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: color == null && divider
              ? const BoxDecoration(
                  border: Border(bottom: BorderSide(color: FlColors.border)),
                )
              : null,
          child: Row(
            children: [
              Expanded(flex: 5, child: cells[0]),
              Expanded(flex: 2, child: cells[1]),
              Expanded(flex: 2, child: cells[2]),
              Expanded(flex: 2, child: cells[3]),
            ],
          ),
        );

    return Container(
      color: FlColors.surface,
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'NHÀ MÁY BÌNH AN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: FlColors.muted,
                ),
              ),
              const Spacer(),
              Text('Số: BC-${period.replaceAll('Tháng ', '')}', style: small),
            ],
          ),
          const Gap(10),
          const Divider(),
          const Gap(20),
          const Text(
            'BIÊN BẢN KIỂM KÊ TÀI SẢN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Gap(10),
          Text('Kỳ báo cáo: $period', style: small),
          const Gap(20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Phạm vi: $scope • Người lập: Hoàng An',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          const Gap(14),
          row([
            const Text(
              'Khu vực',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Kế hoạch',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Đã kiểm kê',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Sai lệch',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ], color: FlColors.surfaceAlt),
          for (final a in areas)
            row([
              Text(a.name, style: cell),
              Text('${a.planned}', style: cell),
              Text('${a.done}', style: cell),
              Text('${a.discrepancies}', style: cell),
            ]),
          const Gap(8),
          row([
            const Text(
              'TỔNG CỘNG',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              flNumber(planned),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              flNumber(done),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: FlColors.primary,
              ),
            ),
            Text(
              '$diff',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: FlColors.warningStrong,
              ),
            ),
          ], divider: false),
          const Gap(20),
          const Row(
            children: [
              Gap(20),
              Text('Người lập biên bản', style: small),
              Spacer(),
              Text('Người xác nhận', style: small),
              Gap(20),
            ],
          ),
          const Gap(30),
          const Text(
            'Trang 1',
            style: TextStyle(fontSize: 9, color: FlColors.muted),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.count,
    required this.label,
    required this.tone,
  });

  final int count;
  final String label;
  final FlTone tone;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 11, color: tone.background),
          const Gap(10),
          Text(
            flNumber(count),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: FlColors.muted),
          ),
        ],
      ),
    );
  }
}
