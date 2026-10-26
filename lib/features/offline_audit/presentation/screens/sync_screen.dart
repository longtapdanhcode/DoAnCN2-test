import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/report_dashboard/presentation/screens/dashboard_screen.dart'
    show auditCode;

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';

import '../audit_actions.dart';
import '../controllers/audit_records_provider.dart';
import '../controllers/sync_controller.dart';

/// Màn hình Đồng bộ dữ liệu (Figma 07 / M05).
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _showHistory = false;
  bool _autoSync = true;
  bool _wifiOnlyPhotos = false;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(finalAuditRecordsProvider);
    final syncState = ref.watch(syncControllerProvider);
    final online = ref.watch(isOnlineProvider).value ?? true;
    final pending = records.where((r) => !r.isSynced).toList();
    final synced = records.where((r) => r.isSynced).toList();

    return ResponsiveLayout.isDesktop(context)
        ? _buildDesktop(pending, synced, syncState, online)
        : _buildMobile(pending, syncState, online);
  }

  Widget _buildDesktop(
    List<AuditRecordModel> pending,
    List<AuditRecordModel> synced,
    AsyncValue<void> syncState,
    bool online,
  ) {
    final failed = syncState.hasError ? pending.length : 0;
    final rows = _showHistory ? synced : pending;

    final queueCard = FlCard(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: CardHeader(title: 'Hàng đợi đồng bộ'),
          ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: FlColors.border)),
              ),
              child: Row(
                children: [
                  _Tab(
                    label: 'Đang chờ ${pending.length}',
                    active: !_showHistory,
                    onTap: () => setState(() => _showHistory = false),
                  ),
                  const Gap(80),
                  _Tab(
                    label: 'Lịch sử đồng bộ',
                    active: _showHistory,
                    onTap: () => setState(() => _showHistory = true),
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),
          Container(
            color: FlColors.surfaceAlt,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: SectionLabel('Phiếu kiểm kê')),
                Expanded(flex: 4, child: SectionLabel('Dữ liệu')),
                Expanded(flex: 3, child: SectionLabel('Trạng thái')),
                Expanded(flex: 2, child: SectionLabel('Thao tác')),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _showHistory
                    ? 'Chưa có phiếu nào được đồng bộ.'
                    : 'Không còn phiếu nào chờ đồng bộ.',
                style: const TextStyle(fontSize: 13, color: FlColors.muted),
              ),
            ),
          for (final r in rows.take(6))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: FlColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auditCode(r),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          r.isSynced ? 'Trên đám mây' : 'Đã lưu trên máy',
                          style: const TextStyle(
                            fontSize: 10,
                            color: FlColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      _dataSummary(r),
                      style: const TextStyle(
                        fontSize: 12,
                        color: FlColors.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: r.isSynced
                          ? const StatusPill(label: 'Đã đồng bộ')
                          : syncState.hasError
                          ? const StatusPill(
                              label: 'Lỗi kết nối',
                              tone: FlTone.danger,
                            )
                          : const StatusPill(label: 'Sẵn sàng'),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: r.isSynced
                        ? const SizedBox()
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: syncState.isLoading
                                  ? null
                                  : () => triggerSync(context, ref),
                              child: Text(
                                syncState.hasError ? 'Thử lại' : 'Đồng bộ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Hiển thị ${rows.length.clamp(0, 6)} trong ${rows.length} phiếu',
              style: const TextStyle(fontSize: 11, color: FlColors.muted),
            ),
          ),
        ],
      ),
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardHeader(title: 'Thiết lập đồng bộ'),
              const Gap(14),
              _SwitchRow(
                label: 'Tự đồng bộ khi có mạng',
                value: _autoSync,
                onChanged: (v) => setState(() => _autoSync = v),
              ),
              const Divider(),
              _SwitchRow(
                label: 'Chỉ tải ảnh qua Wi-Fi',
                value: _wifiOnlyPhotos,
                onChanged: (v) => setState(() => _wifiOnlyPhotos = v),
              ),
              const Gap(18),
              const Text(
                'Ảnh và chữ ký đi cùng từng phiếu.',
                style: TextStyle(fontSize: 11, color: FlColors.muted),
              ),
            ],
          ),
        ),
        const Gap(24),
        FlCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Xử lý dữ liệu khác phiên bản'),
              const Gap(16),
              const StatusPill(label: 'Không có phiếu cần đối chiếu'),
              const Gap(14),
              const Text(
                'So sánh bản trên máy và đám mây để chọn thông tin cần giữ lại.',
                style: TextStyle(
                  fontSize: 12,
                  color: FlColors.muted,
                  height: 1.6,
                ),
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Xem & đối chiếu dữ liệu'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return DesktopPage(
      heading: DesktopPageHeading(
        title: 'Đồng bộ dữ liệu',
        subtitle: 'Quản lý dữ liệu trên thiết bị và theo dõi tiến trình đồng bộ lên đám mây.',
        action: FilledButton.icon(
          onPressed: syncState.isLoading
              ? null
              : () => triggerSync(context, ref),
          icon: syncState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sync_rounded, size: 18),
          label: Text(syncState.isLoading ? 'Đang đồng bộ...' : 'Đồng bộ ngay'),
        ),
      ),
      children: [
        InfoBanner(
          title: 'Dữ liệu đã được lưu an toàn trên thiết bị',
          tone: online ? FlTone.success : FlTone.warning,
          icon: online ? Icons.check_rounded : Icons.cloud_off_rounded,
          subtitle: !online
              ? 'Thiết bị đang ngoại tuyến • ${pending.length} phiếu sẽ được tải lên khi có mạng.'
              : pending.isEmpty
              ? 'Có kết nối Internet • Tất cả phiếu đã có trên đám mây.'
              : 'Có kết nối Internet • ${pending.length} phiếu sẽ được tải lên khi đồng bộ.',
        ),
        const Gap(24),
        FlGrid(
          columns: 4,
          spacing: 24,
          children: [
            _SyncStat(
              label: 'Đã đồng bộ',
              value: synced.length,
              caption: 'Phiếu kiểm kê trên đám mây',
              color: FlColors.primary,
            ),
            _SyncStat(
              label: 'Chờ đồng bộ',
              value: pending.length,
              caption: '${pending.length} phiếu sẵn sàng tải lên',
              color: FlColors.info,
            ),
            const _SyncStat(
              label: 'Cần đối chiếu',
              value: 0,
              caption: 'Dữ liệu khác phiên bản',
              color: FlColors.warning,
            ),
            _SyncStat(
              label: 'Gặp lỗi',
              value: failed,
              caption: failed == 0 ? 'Không có lỗi' : 'Có thể thử lại',
              color: FlColors.danger,
            ),
          ],
        ),
        const Gap(24),
        FlSplitRow(main: queueCard, side: side),
      ],
    );
  }

  Widget _buildMobile(
    List<AuditRecordModel> pending,
    AsyncValue<void> syncState,
    bool online,
  ) {
    final latest = pending.isEmpty ? null : pending.first.timestamp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnotatedRegion<SystemUiOverlayStyle>(
          // Header tối: chữ và biểu tượng thanh trạng thái màu sáng.
          value: SystemUiOverlayStyle.light,
          child: Container(
            color: FlColors.sidebar,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                          tooltip: 'Quay lại',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/reports'),
                        ),
                        const Text(
                          'Đồng bộ dữ liệu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 10, 0, 16),
                      child: Text(
                        'Làm việc liên tục, kể cả khi mất mạng',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: InfoBanner(
                        icon: syncState.hasError || !online
                            ? Icons.cloud_off_rounded
                            : Icons.circle,
                        tone:
                            syncState.hasError || !online || pending.isNotEmpty
                            ? FlTone.warning
                            : FlTone.success,
                        title: !online
                            ? 'Thiết bị đang ngoại tuyến'
                            : syncState.hasError
                            ? 'Chưa kết nối được máy chủ'
                            : pending.isEmpty
                            ? 'Mọi phiếu đã được đồng bộ'
                            : 'Có phiếu đang chờ đồng bộ',
                        subtitle: 'Dữ liệu được giữ an toàn trên máy',
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
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            children: [
              const SectionLabel('Hàng đợi đồng bộ'),
              const Gap(12),
              FlCard(
                padding: const EdgeInsets.all(16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pending.length.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(4),
                            const Text(
                              'mục đang chờ',
                              style: TextStyle(
                                fontSize: 12,
                                color: FlColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Phiếu mới nhất',
                              style: TextStyle(
                                fontSize: 12,
                                color: FlColors.muted,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              latest == null
                                  ? '—'
                                  : '${flDate(latest)}, ${flTime(latest)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(18),
              for (final r in pending.take(5)) ...[
                FlCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const IconTile(
                        icon: Icons.crop_square_rounded,
                        circle: true,
                        size: 34,
                        iconSize: 16,
                      ),
                      const Gap(11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phiếu ${auditCode(r)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(3),
                            Text(
                              '${_dataSummary(r)}  ·  ${flTime(r.timestamp ?? DateTime.now())}',
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
                const Gap(8),
              ],
              const Gap(16),
              FlCard(
                color: FlColors.infoSoft,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tự động đồng bộ khi có mạng',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    const Text(
                      'Phiếu, ảnh và chữ ký sẽ được gửi lên hệ thống. Trạng thái được cập nhật sau khi hoàn tất.',
                      style: TextStyle(fontSize: 12, color: FlColors.muted),
                    ),
                    const Gap(4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: _autoSync,
                        onChanged: (v) => setState(() => _autoSync = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: MobilePrimaryButton(
            label: syncState.hasError ? 'Thử đồng bộ lại' : 'Đồng bộ ngay',
            loading: syncState.isLoading,
            onPressed: () => triggerSync(context, ref),
          ),
        ),
      ],
    );
  }

  String _dataSummary(AuditRecordModel r) {
    final signed = r.signatureBytes?.isNotEmpty ?? false;
    return '${r.quantity} tài sản${signed ? ' • Có chữ ký' : ''}';
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? FlColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: active ? FlColors.primary : FlColors.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SyncStat extends StatelessWidget {
  const _SyncStat({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final String label;
  final int value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: FlColors.muted),
          ),
          const Gap(10),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Gap(14),
          Text(
            caption,
            style: const TextStyle(fontSize: 11, color: FlColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
