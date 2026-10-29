import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:printing/printing.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/pdf_report_generator.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/audit_actions.dart';

import '../../data/models/asset_model.dart';
import '../../domain/entities/asset_status.dart';
import '../controllers/asset_catalog_providers.dart';
import 'asset_editor_screen.dart' show assetStatusTone;

enum _AssetFilter { all, needsCheck, notAudited }

bool _needsCheck(AssetModel a) =>
    a.assetStatus == AssetStatus.check || a.assetStatus == AssetStatus.damaged;

/// Thống kê nhanh của danh mục để hiện trên thẻ và các tab.
class _CatalogStats {
  _CatalogStats(List<AssetModel> assets)
    : total = assets.length,
      good = assets.where((a) => a.assetStatus == AssetStatus.good).length,
      needsCheck = assets.where(_needsCheck).length,
      retired = assets
          .where((a) => a.assetStatus == AssetStatus.retired)
          .length,
      notAudited = assets.where((a) => a.lastAuditAt == null).length;

  final int total;
  final int good;
  final int needsCheck;
  final int retired;
  final int notAudited;
}

/// Màn hình Tài sản & thiết bị (Figma 02 / M06), đọc danh mục thật trên máy.
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key, this.initialArea});

  /// Khu vực lọc sẵn khi mở (ví dụ từ màn Địa điểm).
  final String? initialArea;

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  final _search = TextEditingController();
  _AssetFilter _filter = _AssetFilter.all;
  late String? _area = widget.initialArea;
  String? _status;
  final _selected = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AssetModel> _filtered(List<AssetModel> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((a) {
      if (q.isNotEmpty &&
          !a.name.toLowerCase().contains(q) &&
          !a.code.toLowerCase().contains(q)) {
        return false;
      }
      if (_area != null && a.area != _area) return false;
      if (_status != null && a.assetStatus.label != _status) return false;
      return switch (_filter) {
        _AssetFilter.all => true,
        _AssetFilter.needsCheck => _needsCheck(a),
        _AssetFilter.notAudited => a.lastAuditAt == null,
      };
    }).toList();
  }

  void _addAsset() => context.push('/assets/new');

  void _editAsset(AssetModel a) => context.push('/assets/${a.code}');

  /// Xuất PDF các tài sản đang chọn, hoặc cả danh sách đang lọc nếu chưa chọn.
  Future<void> _exportList(List<AssetModel> visible) async {
    final selected = visible.where((a) => _selected.contains(a.code)).toList();
    final toExport = selected.isNotEmpty ? selected : visible;
    try {
      showFlSnack(context, 'Đang tạo danh sách ${toExport.length} tài sản...');
      final bytes = await PdfReportGenerator.generateAssetList(toExport);
      await Printing.sharePdf(bytes: bytes, filename: 'danh_sach_tai_san.pdf');
    } catch (e) {
      if (mounted) {
        showFlSnack(context, 'Lỗi khi xuất danh sách: $e', tone: FlTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(assetsProvider).value ?? const <AssetModel>[];
    return ResponsiveLayout.isDesktop(context)
        ? _buildDesktop(context, all)
        : _buildMobile(context, all);
  }

  /// Thông báo khi danh mục trên máy còn trống.
  Widget _emptyCatalog() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
    child: Column(
      children: [
        const Text(
          'Chưa có tài sản nào trên máy.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Gap(6),
        const Text(
          'Đồng bộ để tải danh mục tài sản từ máy chủ.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: FlColors.muted),
        ),
        const Gap(14),
        OutlinedButton.icon(
          onPressed: () => triggerSync(context, ref),
          icon: const Icon(Icons.sync_rounded, size: 18),
          label: const Text('Đồng bộ danh mục'),
        ),
      ],
    ),
  );

  String _lastAudit(AssetModel a) =>
      a.lastAuditAt == null ? 'Chưa kiểm kê' : flDate(a.lastAuditAt!);

  Widget _buildDesktop(BuildContext context, List<AssetModel> all) {
    final assets = _filtered(all);
    final stats = _CatalogStats(all);
    final areas = {for (final a in all) ?a.area}.toList()..sort();
    final statuses = [for (final s in AssetStatus.values) s.label];

    return DesktopPage(
      heading: DesktopPageHeading(
        title: 'Tài sản & thiết bị',
        subtitle: 'Danh mục tài sản và tình trạng mới nhất từ các đợt kiểm kê.',
        action: FilledButton.icon(
          onPressed: _addAsset,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm tài sản'),
        ),
      ),
      children: [
        FlCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, m) in [
                  (stats.total, 'Tổng tài sản'),
                  (stats.good, 'Hoạt động tốt'),
                  (stats.needsCheck, 'Cần kiểm tra'),
                  (stats.retired, 'Ngừng sử dụng'),
                ].indexed) ...[
                  if (i > 0)
                    const VerticalDivider(width: 48, color: FlColors.border),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          flNumber(m.$1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(18),
                        Flexible(
                          child: Text(
                            m.$2,
                            style: const TextStyle(
                              fontSize: 12,
                              color: FlColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const Gap(16),
        FlCard(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Tìm theo tên, mã tài sản, số serial…',
                          fillColor: FlColors.background,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: FlColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      flex: 3,
                      child: _FilterDropdown(
                        hint: 'Tất cả khu vực',
                        value: _area,
                        options: areas,
                        onChanged: (v) => setState(() => _area = v),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      flex: 3,
                      child: _FilterDropdown(
                        hint: 'Tất cả tình trạng',
                        value: _status,
                        options: statuses,
                        onChanged: (v) => setState(() => _status = v),
                      ),
                    ),
                    const Spacer(flex: 2),
                    OutlinedButton(
                      onPressed: () => _exportList(assets),
                      child: Text(
                        _selected.isEmpty
                            ? 'Xuất danh sách'
                            : 'Xuất ${_selected.length} đã chọn',
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _Tabs(
                  value: _filter,
                  stats: stats,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),
              const Gap(12),
              Container(
                color: FlColors.surfaceAlt,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 36),
                    Expanded(
                      flex: 5,
                      child: SectionLabel('Tài sản / Mã thiết bị'),
                    ),
                    Expanded(flex: 3, child: SectionLabel('Khu vực')),
                    Expanded(flex: 2, child: SectionLabel('Số lượng')),
                    Expanded(flex: 3, child: SectionLabel('Tình trạng')),
                    Expanded(flex: 2, child: SectionLabel('Kiểm kê gần nhất')),
                  ],
                ),
              ),
              if (all.isEmpty)
                _emptyCatalog()
              else if (assets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Không có tài sản phù hợp với bộ lọc.',
                    style: TextStyle(fontSize: 13, color: FlColors.muted),
                  ),
                ),
              for (final a in assets) _buildTableRow(a),
              const Gap(20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Hiển thị ${flNumber(assets.length)} trong ${flNumber(stats.total)} tài sản',
                      style: const TextStyle(
                        fontSize: 12,
                        color: FlColors.muted,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => triggerSync(context, ref),
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Đồng bộ danh mục'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(AssetModel a) {
    final checked = _selected.contains(a.code);
    return InkWell(
      onTap: () => _editAsset(a),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FlColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Checkbox(
                value: checked,
                visualDensity: VisualDensity.compact,
                onChanged: (v) => setState(
                  () => v! ? _selected.add(a.code) : _selected.remove(a.code),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  const IconTile(
                    icon: Icons.inventory_2_outlined,
                    tone: FlTone.neutral,
                    size: 38,
                    iconSize: 18,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(3),
                        Text(
                          a.isSynced ? a.code : '${a.code}  •  Chờ đồng bộ',
                          style: TextStyle(
                            fontSize: 11,
                            color: a.isSynced
                                ? FlColors.muted
                                : FlColors.warningStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(a.area ?? '—', style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${a.quantity}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(
                  label: a.assetStatus.label,
                  tone: assetStatusTone(a.assetStatus),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _lastAudit(a),
                style: const TextStyle(fontSize: 12, color: FlColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, List<AssetModel> all) {
    final assets = _filtered(all);
    final stats = _CatalogStats(all);
    final chips = [
      (_AssetFilter.all, 'Tất cả ${flNumber(stats.total)}'),
      (_AssetFilter.notAudited, 'Chưa kiểm ${stats.notAudited}'),
      (_AssetFilter.needsCheck, 'Cần xử lý ${stats.needsCheck}'),
    ];

    return MobilePage(
      title: 'Tài sản & thiết bị',
      trailing: IconButton.filled(
        onPressed: _addAsset,
        tooltip: 'Thêm tài sản',
        style: IconButton.styleFrom(backgroundColor: FlColors.primary),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Tìm theo tên hoặc mã tài sản',
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: FlColors.muted,
            ),
          ),
        ),
        const Gap(16),
        Row(
          children: [
            for (final (i, c) in chips.indexed) ...[
              if (i > 0) const Gap(8),
              Expanded(
                child: _MobileChip(
                  label: c.$2,
                  active: _filter == c.$1,
                  onTap: () => setState(() => _filter = c.$1),
                ),
              ),
            ],
          ],
        ),
        const Gap(20),
        SectionLabel('${assets.length} tài sản  ·  tất cả khu vực'),
        const Gap(10),
        if (all.isEmpty)
          FlCard(padding: EdgeInsets.zero, child: _emptyCatalog())
        else if (assets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Không có tài sản phù hợp.',
              style: TextStyle(fontSize: 13, color: FlColors.muted),
            ),
          ),
        for (final a in assets) ...[
          FlCard(
            padding: const EdgeInsets.all(13),
            onTap: () => _editAsset(a),
            child: Row(
              children: [
                const IconTile(
                  icon: Icons.crop_square_rounded,
                  tone: FlTone.info,
                  size: 56,
                  iconSize: 22,
                ),
                const Gap(13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        [a.code, ?a.category].join('  ·  '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: FlColors.muted,
                        ),
                      ),
                      const Gap(6),
                      Row(
                        children: [
                          StatusPill(
                            label: a.assetStatus.label,
                            tone: assetStatusTone(a.assetStatus),
                            bold: true,
                          ),
                          if (!a.isSynced) ...[
                            const Gap(6),
                            const StatusPill(
                              label: 'Chờ đồng bộ',
                              tone: FlTone.warning,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
        ],
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: FlColors.ink,
      ),
      decoration: const InputDecoration(),
      items: [
        DropdownMenuItem(value: null, child: Text(hint)),
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: onChanged,
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.value,
    required this.stats,
    required this.onChanged,
  });

  final _AssetFilter value;
  final _CatalogStats stats;
  final ValueChanged<_AssetFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_AssetFilter.all, 'Tất cả tài sản'),
      (_AssetFilter.needsCheck, 'Cần kiểm tra ${stats.needsCheck}'),
      (_AssetFilter.notAudited, 'Chưa kiểm kê ${stats.notAudited}'),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FlColors.border)),
      ),
      child: Row(
        children: [
          for (final t in tabs)
            InkWell(
              onTap: () => onChanged(t.$1),
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 6, 40, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: value == t.$1
                          ? FlColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == t.$1 ? FlColors.primary : FlColors.muted,
                    fontWeight: value == t.$1
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileChip extends StatelessWidget {
  const _MobileChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? FlColors.primary : FlColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: active ? FlColors.primary : FlColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : FlColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
