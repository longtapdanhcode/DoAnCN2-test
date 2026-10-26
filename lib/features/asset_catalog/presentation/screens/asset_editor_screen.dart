import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

import '../../data/models/asset_model.dart';
import '../../domain/entities/asset_status.dart';
import '../controllers/asset_catalog_providers.dart';

/// Màu hiển thị cho từng tình trạng tài sản.
FlTone assetStatusTone(AssetStatus status) => switch (status) {
  AssetStatus.good => FlTone.success,
  AssetStatus.check => FlTone.warning,
  AssetStatus.damaged => FlTone.danger,
  AssetStatus.retired => FlTone.neutral,
};

/// Màn thêm mới (khi [code] là `null`) hoặc sửa một tài sản trong danh mục.
///
/// Lưu trên máy trước; nếu đang có mạng thì đẩy lên Supabase ngay, còn không
/// tài sản sẽ được đẩy ở lần đồng bộ sau.
class AssetEditorScreen extends ConsumerStatefulWidget {
  const AssetEditorScreen({super.key, this.code});

  final String? code;

  bool get isNew => code == null;

  @override
  ConsumerState<AssetEditorScreen> createState() => _AssetEditorScreenState();
}

class _AssetEditorScreenState extends ConsumerState<AssetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _area = TextEditingController();
  final _location = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  AssetStatus _status = AssetStatus.good;

  /// Bản đang sửa (giữ lại các trường form không hiển thị như lastAuditAt).
  AssetModel? _original;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isNew) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final asset = await ref
        .read(assetCatalogRepositoryProvider)
        .findByCode(widget.code!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _original = asset;
      if (asset != null) {
        _code.text = asset.code;
        _name.text = asset.name;
        _category.text = asset.category ?? '';
        _area.text = asset.area ?? '';
        _location.text = asset.location ?? '';
        _quantity.text = '${asset.quantity}';
        _status = asset.assetStatus;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_code, _name, _category, _area, _location, _quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _clean(String text) {
    final t = text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(assetCatalogRepositoryProvider);
    final code = _code.text.trim().toUpperCase();

    if (widget.isNew && await repo.findByCode(code) != null) {
      if (mounted) {
        showFlSnack(
          context,
          'Mã $code đã có trong danh mục. Hãy dùng mã khác hoặc sửa tài sản đó.',
          tone: FlTone.warning,
        );
      }
      return;
    }

    setState(() => _saving = true);
    final asset = (_original ?? AssetModel(code))
      ..name = _name.text.trim()
      ..category = _clean(_category.text)
      ..area = _clean(_area.text)
      ..location = _clean(_location.text)
      ..quantity = int.parse(_quantity.text.trim())
      ..status = _status.code;

    try {
      await repo.save(asset);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showFlSnack(context, 'Không lưu được tài sản: $e', tone: FlTone.danger);
      }
      return;
    }

    // Có mạng thì đẩy lên ngay; lỗi ở đây không làm mất dữ liệu trên máy.
    var synced = false;
    if (checkOnline(ref)) {
      try {
        await repo.sync();
        synced = true;
      } catch (e) {
        debugPrint('[AssetEditor] Chưa đồng bộ được tài sản: $e');
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    showFlSnack(
      context,
      synced
          ? 'Đã lưu và đồng bộ tài sản $code.'
          : 'Đã lưu tài sản $code trên máy, sẽ đồng bộ khi có mạng.',
      tone: FlTone.success,
    );
    context.canPop() ? context.pop() : context.go('/assets');
  }

  void _startAudit() {
    context.push(
      '/audit-form',
      extra: {
        'scanCode': _code.text.trim(),
        'aiLabel': _clean(_category.text) ?? _name.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi để checkOnline() có giá trị khi bấm Lưu.
    ref.watch(isOnlineProvider);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!widget.isNew && _original == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Không tìm thấy tài sản ${widget.code} trên máy.',
            style: const TextStyle(color: FlColors.muted),
          ),
        ),
      );
    }

    final title = widget.isNew ? 'Thêm tài sản' : 'Sửa tài sản';
    final fields = _buildFields();

    return Form(
      key: _formKey,
      child: ResponsiveLayout.isDesktop(context)
          ? DesktopPage(
              heading: DesktopPageHeading(
                title: title,
                subtitle: widget.isNew
                    ? 'Thêm tài sản mới vào danh mục dùng chung.'
                    : 'Cập nhật thông tin và tình trạng của tài sản.',
              ),
              children: [
                FlCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: fields.code),
                          const Gap(16),
                          Expanded(flex: 2, child: fields.name),
                        ],
                      ),
                      const Gap(16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: fields.category),
                          const Gap(16),
                          Expanded(child: fields.quantity),
                        ],
                      ),
                      const Gap(16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: fields.area),
                          const Gap(16),
                          Expanded(child: fields.location),
                        ],
                      ),
                      const Gap(20),
                      fields.status,
                    ],
                  ),
                ),
                const Gap(16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => context.canPop()
                                ? context.pop()
                                : context.go('/assets'),
                      child: const Text('Huỷ'),
                    ),
                    if (!widget.isNew) ...[
                      const Gap(12),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _startAudit,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Lập phiếu kiểm kê'),
                      ),
                    ],
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(_saving ? 'Đang lưu...' : 'Lưu tài sản'),
                    ),
                  ],
                ),
              ],
            )
          : MobilePage(
              title: title,
              showBack: true,
              trailing: widget.isNew
                  ? null
                  : TextButton(
                      onPressed: _saving ? null : _startAudit,
                      child: const Text('Lập phiếu'),
                    ),
              bottomAction: MobilePrimaryButton(
                label: 'Lưu tài sản',
                loading: _saving,
                onPressed: _save,
              ),
              children: [
                fields.code,
                const Gap(14),
                fields.name,
                const Gap(14),
                fields.category,
                const Gap(14),
                fields.quantity,
                const Gap(14),
                fields.area,
                const Gap(14),
                fields.location,
                const Gap(20),
                fields.status,
              ],
            ),
    );
  }

  ({
    Widget code,
    Widget name,
    Widget category,
    Widget quantity,
    Widget area,
    Widget location,
    Widget status,
  })
  _buildFields() {
    return (
      code: FlTextField(
        label: 'Mã tài sản *',
        controller: _code,
        hint: 'Ví dụ: TS-DC-0142',
        enabled: widget.isNew,
        textCapitalization: TextCapitalization.characters,
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return 'Vui lòng nhập mã tài sản';
          if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(t)) {
            return 'Chỉ dùng chữ, số, dấu chấm, gạch ngang, gạch dưới';
          }
          return null;
        },
      ),
      name: FlTextField(
        label: 'Tên tài sản *',
        controller: _name,
        hint: 'Ví dụ: Động cơ điện Siemens 3 pha',
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Vui lòng nhập tên tài sản'
            : null,
      ),
      category: FlTextField(
        label: 'Loại thiết bị',
        controller: _category,
        hint: 'Ví dụ: Thiết bị truyền động',
      ),
      quantity: FlTextField(
        label: 'Số lượng *',
        controller: _quantity,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          final n = int.tryParse(v?.trim() ?? '');
          if (n == null) return 'Vui lòng nhập số lượng';
          if (n < 0) return 'Số lượng không hợp lệ';
          return null;
        },
      ),
      area: FlTextField(
        label: 'Khu vực',
        controller: _area,
        hint: 'Ví dụ: Xưởng sản xuất A',
      ),
      location: FlTextField(
        label: 'Vị trí cụ thể',
        controller: _location,
        hint: 'Ví dụ: Dây chuyền 02 • Kệ A3',
      ),
      status: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tình trạng',
            style: TextStyle(fontSize: 12, color: FlColors.muted),
          ),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in AssetStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _status == s,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _status = s),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: _status == s
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _status == s
                        ? assetStatusTone(s).foreground
                        : FlColors.muted,
                  ),
                  selectedColor: assetStatusTone(s).background,
                  backgroundColor: FlColors.surface,
                  side: BorderSide(
                    color: _status == s ? Colors.transparent : FlColors.border,
                  ),
                  shape: const StadiumBorder(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
