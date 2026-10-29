import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/ai_pipeline/ai_config.dart';
import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/account_sheet.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/sync_settings_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/auto_sync_controller.dart';

import '../../data/workspace_settings.dart';
import '../workspace_page.dart';

/// Màn Cài đặt (Card 27): tài khoản, nơi kiểm kê, đồng bộ, nhận diện AI và
/// dữ liệu trên máy.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = <Widget>[
      const _AccountSection(),
      const _WorkspaceSection(),
      const _SyncSection(),
      const _AiSection(),
      const _DataSection(),
    ];

    return WorkspacePage(
      title: 'Cài đặt',
      subtitle: 'Tài khoản, nơi kiểm kê và cách app đồng bộ dữ liệu.',
      children: ResponsiveLayout.isDesktop(context)
          ? [FlGrid(columns: 2, spacing: 20, children: sections)]
          : [
              for (final s in sections) ...[s, const Gap(16)],
            ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(title: title),
          const Gap(14),
          ...children,
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(signedInUserProvider);
    return _Section(
      title: 'Tài khoản',
      children: [
        if (user != null) ...[
          _Info(label: 'Họ tên', value: user.displayName),
          _Info(label: 'Email', value: user.email),
          _Info(label: 'Vai trò', value: user.role.label),
          const Gap(14),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () async {
              if (!await confirmSignOut(context, ref)) return;
              await ref.read(authRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceSection extends ConsumerStatefulWidget {
  const _WorkspaceSection();

  @override
  ConsumerState<_WorkspaceSection> createState() => _WorkspaceSectionState();
}

class _WorkspaceSectionState extends ConsumerState<_WorkspaceSection> {
  late final _site = TextEditingController(
    text: ref.read(workspaceProvider).siteName,
  );
  late String _shift = ref.read(workspaceProvider).shift;
  bool _edited = false;

  @override
  void dispose() {
    _site.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final site = _site.text.trim();
    if (site.isEmpty) {
      showFlSnack(context, 'Nhập tên nơi kiểm kê', tone: FlTone.warning);
      return;
    }
    await ref
        .read(workspaceSettingsProvider.notifier)
        .save(WorkspaceSettings(siteName: site, shift: _shift));
    if (!mounted) return;
    setState(() => _edited = false);
    showFlSnack(context, 'Đã lưu nơi kiểm kê', tone: FlTone.success);
  }

  @override
  Widget build(BuildContext context) {
    // Thiết lập đọc xong sau lần dựng đầu: cập nhật ô nhập nếu chưa sửa.
    ref.listen(workspaceProvider, (_, next) {
      if (_edited) return;
      _site.text = next.siteName;
      setState(() => _shift = next.shift);
    });

    return _Section(
      title: 'Nơi kiểm kê',
      children: [
        FlTextField(
          label: 'Tên nhà máy / kho',
          controller: _site,
          textCapitalization: TextCapitalization.words,
        ),
        const Gap(14),
        const Text(
          'Ca làm việc',
          style: TextStyle(fontSize: 12, color: FlColors.muted),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in workShifts)
              ChoiceChip(
                label: Text(s),
                selected: s == _shift,
                onSelected: (_) => setState(() {
                  _shift = s;
                  _edited = true;
                }),
              ),
          ],
        ),
        const Gap(16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Hiển thị ở Tổng quan và thanh bên.',
                style: TextStyle(fontSize: 11, color: FlColors.muted),
              ),
            ),
            FilledButton(onPressed: _save, child: const Text('Lưu')),
          ],
        ),
      ],
    );
  }
}

class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(syncSettingsProvider).value ?? const SyncSettings();
    final notifier = ref.read(syncSettingsProvider.notifier);
    return _Section(
      title: 'Đồng bộ',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tự đồng bộ khi có mạng'),
          subtitle: const Text('Phiếu đã ký tự gửi lên, không cần bấm.'),
          value: settings.autoSync,
          onChanged: notifier.setAutoSync,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Chỉ tải ảnh qua Wi-Fi'),
          subtitle: const Text('Phiếu có ảnh chờ Wi-Fi khi tự đồng bộ.'),
          value: settings.wifiOnlyPhotos,
          onChanged: notifier.setWifiOnlyPhotos,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go('/sync'),
            child: const Text('Mở màn Đồng bộ dữ liệu  ›'),
          ),
        ),
      ],
    );
  }
}

class _AiSection extends StatelessWidget {
  const _AiSection();

  @override
  Widget build(BuildContext context) {
    String pct(double v) => '${(v * 100).round()}%';
    return _Section(
      title: 'Nhận diện AI trên máy',
      children: [
        _Info(label: 'Mô hình', value: AiConfig.modelPath.split('/').last),
        const _Info(
          label: 'Kích thước ảnh vào',
          value: '${AiConfig.inputSize} × ${AiConfig.inputSize}',
        ),
        _Info(
          label: 'Ngưỡng thiết bị',
          value: pct(AiConfig.confidenceThreshold),
        ),
        _Info(
          label: 'Ngưỡng lỗi / hư hỏng',
          value: pct(AiConfig.defectConfidenceThreshold),
        ),
        const Gap(8),
        const Text(
          'Ảnh camera được xử lý ngay trên máy, không gửi lên máy chủ.',
          style: TextStyle(fontSize: 11, color: FlColors.muted),
        ),
      ],
    );
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signed = ref.watch(finalAuditRecordsProvider).length;
    final drafts = ref.watch(draftAuditRecordsProvider).length;
    final pending = ref.watch(pendingSyncCountProvider);
    final assets = ref.watch(assetsProvider).value?.length ?? 0;
    final conflicts = ref.watch(assetConflictsProvider).length;
    return _Section(
      title: 'Dữ liệu trên máy',
      children: [
        _Info(label: 'Phiếu đã ký', value: '$signed'),
        _Info(label: 'Bản nháp', value: '$drafts'),
        _Info(label: 'Chờ đồng bộ', value: '$pending'),
        _Info(label: 'Tài sản trong danh mục', value: '$assets'),
        _Info(label: 'Tài sản cần đối chiếu', value: '$conflicts'),
        const Gap(8),
        const Text(
          'Dữ liệu vẫn giữ trên máy khi đăng xuất.',
          style: TextStyle(fontSize: 11, color: FlColors.muted),
        ),
      ],
    );
  }
}

/// Một dòng "nhãn: giá trị" dạng chữ.
class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return KeyValueRow(
      label: label,
      value: Text(value, style: const TextStyle(fontSize: 13)),
    );
  }
}
