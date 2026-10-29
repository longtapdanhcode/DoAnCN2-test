import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

import '../../data/models/asset_model.dart';
import '../../domain/asset_merge.dart';
import '../controllers/asset_catalog_providers.dart';

/// Đối chiếu dữ liệu khác phiên bản (Card 25): tài sản bị sửa ở cả máy này
/// và trên đám mây, người dùng chọn giá trị cần giữ cho từng mục.
class AssetConflictsScreen extends ConsumerWidget {
  const AssetConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts = ref.watch(assetConflictsProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/sync'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đối chiếu dữ liệu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        conflicts.isEmpty
                            ? 'Không còn dữ liệu khác phiên bản'
                            : '${conflicts.length} tài sản khác phiên bản',
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
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (conflicts.isEmpty)
                      const InfoBanner(
                        icon: Icons.check_circle_rounded,
                        title: 'Không còn tài sản nào cần đối chiếu',
                        subtitle: 'Dữ liệu trên máy và đám mây đã khớp nhau.',
                      )
                    else ...[
                      const Text(
                        'Máy này và đám mây (thiết bị khác) cùng sửa các tài sản dưới đây. '
                        'Mục chỉ một bên sửa đã được gộp tự động; chọn giá trị cần giữ cho các mục còn lại.',
                        style: TextStyle(
                          fontSize: 13,
                          color: FlColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const Gap(16),
                      for (final asset in conflicts) ...[
                        _ConflictCard(
                          key: ValueKey('${asset.code}-${asset.conflictJson}'),
                          asset: asset,
                        ),
                        const Gap(16),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends ConsumerStatefulWidget {
  const _ConflictCard({super.key, required this.asset});

  final AssetModel asset;

  @override
  ConsumerState<_ConflictCard> createState() => _ConflictCardState();
}

class _ConflictCardState extends ConsumerState<_ConflictCard> {
  final Set<String> _useRemote = {};
  bool _saving = false;

  Future<void> _resolve(Set<String> useRemote) async {
    setState(() => _saving = true);
    final repo = ref.read(assetCatalogRepositoryProvider);
    final code = widget.asset.code;
    try {
      await repo.resolveConflict(code, useRemote);
      // Đẩy lựa chọn lên ngay nếu có mạng; không thì lần đồng bộ sau sẽ đẩy.
      var note = 'Sẽ gửi lên khi có mạng.';
      if (checkOnline(ref)) {
        try {
          final result = await repo.sync();
          note = result.conflicts > 0
              ? 'Còn ${result.conflicts} tài sản cần đối chiếu.'
              : 'Đã cập nhật lên đám mây.';
        } catch (e) {
          debugPrint('[Conflicts] Lỗi đồng bộ sau khi đối chiếu: $e');
          note = 'Chưa gửi được lên đám mây, sẽ thử lại khi đồng bộ.';
        }
      }
      if (mounted) {
        showFlSnack(context, 'Đã đối chiếu $code. $note', tone: FlTone.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showFlSnack(context, 'Lỗi khi đối chiếu: $e', tone: FlTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remote = widget.asset.conflictRemote;
    if (remote == null) return const SizedBox.shrink();
    final local = assetContent(widget.asset);
    final cloud = assetContent(remote);
    final fields = differingFields(local, cloud);

    return FlCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.asset.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      widget.asset.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FlColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusPill(label: 'Khác phiên bản', tone: FlTone.warning),
            ],
          ),
          const Gap(6),
          Text(
            'Trên máy sửa ${flDate(widget.asset.updatedAt)} ${flTime(widget.asset.updatedAt)}'
            ' • Đám mây sửa ${flDate(remote.updatedAt)} ${flTime(remote.updatedAt)}',
            style: const TextStyle(fontSize: 11, color: FlColors.muted),
          ),
          for (final key in fields) ...[
            const Gap(16),
            Text(
              assetFieldLabels[key]!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: _ChoiceTile(
                    source: 'Trên máy',
                    value: displayField(key, local[key]),
                    selected: !_useRemote.contains(key),
                    onTap: _saving
                        ? null
                        : () => setState(() => _useRemote.remove(key)),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _ChoiceTile(
                    source: 'Đám mây',
                    value: displayField(key, cloud[key]),
                    selected: _useRemote.contains(key),
                    onTap: _saving
                        ? null
                        : () => setState(() => _useRemote.add(key)),
                  ),
                ),
              ],
            ),
          ],
          const Gap(18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => _resolve(const {}),
                child: const Text('Giữ bản trên máy'),
              ),
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => _resolve({...assetFieldLabels.keys}),
                child: const Text('Lấy bản đám mây'),
              ),
              FilledButton(
                onPressed: _saving ? null : () => _resolve({..._useRemote}),
                child: Text(_saving ? 'Đang lưu...' : 'Lưu lựa chọn'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.source,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String source;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$source: $value',
      child: FlCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        color: selected ? FlColors.infoSoft : FlColors.surface,
        borderColor: selected ? FlColors.info : FlColors.border,
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: selected ? FlColors.info : FlColors.muted,
            ),
            const Gap(8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source,
                    style: const TextStyle(fontSize: 11, color: FlColors.muted),
                  ),
                  const Gap(2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
