import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/auth/domain/app_user.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/features/workspace/presentation/workspace_page.dart';

import '../data/repair_rate_repository.dart';
import '../domain/entities/damage_enums.dart';
import '../domain/entities/repair_rate.dart';
import 'damage_format.dart';
import 'repair_cost_card.dart';

/// Màn "Bảng đơn giá sửa chữa": ai cũng xem được; chỉ admin thêm/sửa/xoá
/// (ghi thẳng lên Supabase, RLS chặn tài khoản khác).
class RepairRatesScreen extends ConsumerWidget {
  const RepairRatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(repairRateTableProvider);
    final isAdmin = ref.watch(signedInUserProvider)?.role == UserRole.admin;

    return WorkspacePage(
      title: 'Bảng đơn giá sửa chữa',
      subtitle: isAdmin
          ? 'Đơn giá dùng để tính chi phí trên phiếu đánh giá hư hỏng.'
          : 'Chỉ quản trị viên được sửa đơn giá.',
      children: [
        table.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => InfoBanner(
            icon: Icons.error_outline,
            tone: FlTone.danger,
            title: 'Không tải được bảng đơn giá',
            subtitle: '$e',
          ),
          data: (t) => _RatesBody(table: t, isAdmin: isAdmin),
        ),
      ],
    );
  }
}

class _RatesBody extends ConsumerWidget {
  const _RatesBody({required this.table, required this.isAdmin});

  final RepairRateTable table;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (tone, title, subtitle) = switch (table.source) {
      RepairRateSource.remote => (
        FlTone.success,
        'Đang dùng bảng giá trên máy chủ',
        'Điện thoại tải bảng này về để tính tiền cả khi ngoại tuyến.',
      ),
      RepairRateSource.cache => (
        FlTone.info,
        'Ngoại tuyến: bảng giá đã lưu lần trước',
        'Kết nối mạng để tải bảng mới nhất.',
      ),
      RepairRateSource.sample => (
        FlTone.warning,
        'Chưa tải được bảng giá: đang dùng giá minh hoạ',
        'Máy chủ chưa có đơn giá hoặc chưa kết nối được.',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoBanner(
          icon: Icons.payments_outlined,
          tone: tone,
          title: title,
          subtitle: subtitle,
        ),
        if (table.hasSampleRates) ...[
          const Gap(10),
          const InfoBanner(
            icon: Icons.warning_amber_rounded,
            tone: FlTone.warning,
            title: 'Có đơn giá minh hoạ',
            subtitle:
                'Các dòng đánh dấu "Minh hoạ" chưa phải giá thật của nhà trường. '
                'Quản trị viên sửa lại giá để bỏ đánh dấu.',
          ),
        ],
        const Gap(16),
        if (isAdmin && table.source == RepairRateSource.remote)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('add-rate'),
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm đơn giá'),
            ),
          ),
        if (isAdmin && table.source != RepairRateSource.remote)
          const Text(
            'Cần kết nối máy chủ để sửa đơn giá.',
            style: TextStyle(fontSize: 12, color: FlColors.muted),
          ),
        const Gap(12),
        for (final type in DamageType.values) ...[
          _TypeCard(
            type: type,
            rates: [
              for (final r in table.rates)
                if (r.damageType == type) r,
            ]..sort(_order),
            onEdit: isAdmin && table.source == RepairRateSource.remote
                ? (r) => _edit(context, ref, r)
                : null,
          ),
          const Gap(12),
        ],
      ],
    );
  }

  static int _order(RepairRate a, RepairRate b) {
    final m = (a.material?.index ?? -1).compareTo(b.material?.index ?? -1);
    return m != 0 ? m : a.severity.index.compareTo(b.severity.index);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    RepairRate? rate,
  ) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => _RateDialog(initial: rate),
    );
    if (result == null || !context.mounted) return;
    final writer = ref.read(repairRateWriterProvider);
    try {
      if (result.delete) {
        await writer.delete(rate!);
      } else {
        // Đổi tổ hợp (chất liệu/loại/mức) khi sửa: xoá dòng cũ để không trùng.
        final old = rate;
        final changedKey =
            old != null &&
            (old.material != result.rate.material ||
                old.damageType != result.rate.damageType ||
                old.severity != result.rate.severity);
        await writer.upsert(result.rate);
        if (changedKey) await writer.delete(old);
      }
      ref.invalidate(repairRateTableProvider);
      if (context.mounted) {
        showFlSnack(
          context,
          result.delete ? 'Đã xoá đơn giá.' : 'Đã lưu đơn giá.',
          tone: FlTone.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showFlSnack(context, 'Không lưu được: $e', tone: FlTone.danger);
      }
    }
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type, required this.rates, this.onEdit});

  final DamageType type;
  final List<RepairRate> rates;
  final ValueChanged<RepairRate>? onEdit;

  @override
  Widget build(BuildContext context) {
    return FlCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            title: type.label,
            subtitle: 'Tính theo ${type.unit.symbol}',
          ),
          const Gap(8),
          if (rates.isEmpty)
            const Text(
              'Chưa có đơn giá: phiếu có loại hư hỏng này sẽ chưa có tiền.',
              style: TextStyle(fontSize: 13, color: FlColors.warning),
            ),
          for (final r in rates)
            InkWell(
              onTap: onEdit == null ? null : () => onEdit!(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Cố định độ rộng để cột chất liệu thẳng hàng.
                    SizedBox(
                      width: 64,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(
                          label: r.severity.label,
                          tone: severityTone(r.severity),
                        ),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.material?.label ?? 'Mọi chất liệu',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (r.method.isNotEmpty)
                            Text(
                              r.method,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FlColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (r.isSample) ...[
                      const StatusPill(label: 'Minh hoạ', tone: FlTone.warning),
                      const Gap(8),
                    ],
                    Text(
                      '${formatVnd(r.unitPrice)}/${r.unit.symbol}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (onEdit != null) ...[
                      const Gap(4),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: FlColors.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditResult {
  const _EditResult(this.rate, {this.delete = false});

  final RepairRate rate;
  final bool delete;
}

/// Hộp thoại thêm/sửa một đơn giá.
class _RateDialog extends StatefulWidget {
  const _RateDialog({this.initial});

  final RepairRate? initial;

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  late SurfaceMaterial? _material = widget.initial?.material;
  late DamageType _type = widget.initial?.damageType ?? DamageType.crack;
  late DamageSeverity _severity =
      widget.initial?.severity ?? DamageSeverity.light;
  late final _price = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.unitPrice.round().toString(),
  );
  late final _method = TextEditingController(
    text: widget.initial?.method ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _method.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_price.text.replaceAll('.', '').trim());
    if (price == null || price < 0) {
      setState(() => _error = 'Nhập đơn giá (VND), ví dụ 150000');
      return;
    }
    Navigator.pop(
      context,
      _EditResult(
        RepairRate(
          material: _material,
          damageType: _type,
          severity: _severity,
          unitPrice: price,
          method: _method.text.trim(),
          // Quản trị viên đã nhập giá: không còn là giá minh hoạ.
          isSample: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? 'Sửa đơn giá' : 'Thêm đơn giá'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<DamageType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Loại hư hỏng'),
              items: [
                for (final t in DamageType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const Gap(12),
            DropdownButtonFormField<DamageSeverity>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Mức độ'),
              items: [
                for (final s in DamageSeverity.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (s) => setState(() => _severity = s ?? _severity),
            ),
            const Gap(12),
            DropdownButtonFormField<SurfaceMaterial?>(
              initialValue: _material,
              decoration: const InputDecoration(labelText: 'Chất liệu'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Mọi chất liệu'),
                ),
                for (final m in SurfaceMaterial.values)
                  DropdownMenuItem(value: m, child: Text(m.label)),
              ],
              onChanged: (m) => setState(() => _material = m),
            ),
            const Gap(12),
            TextField(
              key: const Key('rate-price'),
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Đơn giá',
                suffixText: 'đ/${_type.unit.symbol}',
                errorText: _error,
              ),
            ),
            const Gap(12),
            TextField(
              controller: _method,
              decoration: const InputDecoration(labelText: 'Cách xử lý'),
            ),
          ],
        ),
      ),
      actions: [
        if (editing)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _EditResult(widget.initial!, delete: true),
            ),
            style: TextButton.styleFrom(foregroundColor: FlColors.danger),
            child: const Text('Xoá'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}
