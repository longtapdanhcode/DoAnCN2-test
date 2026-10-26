import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/canvas_signature/presentation/screens/signature_screen.dart';

import '../../data/models/audit_record_model.dart';
import '../../domain/entities/audit_condition.dart';
import '../controllers/audit_form_controller.dart';
import '../controllers/audit_records_provider.dart';

/// Màu hiển thị cho từng tình trạng thiết bị.
extension AuditConditionTone on AuditCondition {
  FlTone get tone => switch (this) {
    AuditCondition.good => FlTone.success,
    AuditCondition.check => FlTone.warning,
    AuditCondition.damaged => FlTone.danger,
  };
}

/// Màn hình Lập phiếu kiểm kê (Figma 04 / M03).
///
/// Nhận dữ liệu quét mã từ camera scanner và nhãn do On-Device AI nhận diện,
/// cho phép người kiểm kê xác nhận thông tin, nhập số lượng rồi chuyển sang
/// bước ký xác nhận trước khi lưu.
class AuditFormScreen extends ConsumerStatefulWidget {
  final String initialScanCode;
  final String? initialAiLabel;

  /// Khác `null` khi mở lại một bản nháp để ký và hoàn tất.
  final int? draftId;

  const AuditFormScreen({
    super.key,
    required this.initialScanCode,
    this.initialAiLabel,
    this.draftId,
  });

  @override
  ConsumerState<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends ConsumerState<AuditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scanCodeController;
  late final TextEditingController _aiLabelController;
  late final TextEditingController _nameController;
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _createdAt;
  int _quantity = 1;
  AuditCondition _condition = AuditCondition.good;

  @override
  void initState() {
    super.initState();
    _createdAt = DateTime.now();
    _scanCodeController = TextEditingController(text: widget.initialScanCode);
    _aiLabelController = TextEditingController(
      text: widget.initialAiLabel ?? '',
    );
    _nameController = TextEditingController(text: widget.initialAiLabel ?? '');
    if (widget.draftId != null) {
      // Phải lắng nghe (không dùng ref.read(...).future): Riverpod 3 tạm dừng
      // provider không có người nghe nên danh sách phiếu có thể không về.
      _draftSub = ref.listenManual(
        auditRecordsProvider,
        (_, next) => _applyDraft(next.value),
        fireImmediately: true,
      );
    }
  }

  ProviderSubscription<AsyncValue<List<AuditRecordModel>>>? _draftSub;
  bool _draftLoaded = false;

  /// Điền sẵn form từ bản nháp đã lưu để người dùng ký và hoàn tất.
  void _applyDraft(List<AuditRecordModel>? records) {
    if (_draftLoaded || records == null) return;
    final draft = records.where((r) => r.id == widget.draftId).firstOrNull;
    if (draft == null) return;
    _draftLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _scanCodeController.text = draft.scanCode ?? '';
        _aiLabelController.text = draft.aiDetectedLabel ?? '';
        _nameController.text = draft.assetName ?? '';
        _areaController.text = draft.area ?? '';
        _locationController.text = draft.location ?? '';
        _notesController.text = draft.notes ?? '';
        _quantity = draft.quantity < 1 ? 1 : draft.quantity;
        _condition = AuditCondition.fromCode(draft.condition) ?? _condition;
        _createdAt = draft.timestamp ?? _createdAt;
      });
    });
  }

  @override
  void dispose() {
    _draftSub?.close();
    _scanCodeController.dispose();
    _aiLabelController.dispose();
    _nameController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Tăng/giảm số lượng thông qua các nút thao tác nhanh
  void _adjustQuantity(int delta) {
    setState(() => _quantity = (_quantity + delta).clamp(1, 999999));
  }

  AuditSummary get _summary => AuditSummary(
    scanCode: _scanCodeController.text.trim(),
    label: _aiLabelController.text.trim(),
    name: _nameController.text.trim(),
    area: _areaController.text.trim(),
    location: _locationController.text.trim(),
    quantity: _quantity,
    condition: _condition.label,
    conditionTone: _condition.tone,
    createdAt: _createdAt,
  );

  /// Kiểm tra form, mở màn hình ký và lưu phiếu khi đã có chữ ký.
  Future<void> _continueToSignature() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final signed = await context.push<SignatureResult?>(
      '/signature',
      extra: _summary,
    );
    if (signed != null && mounted) {
      await _save(signed);
    }
  }

  /// Lưu bản ghi vào database; [signed] là `null` khi lưu bản nháp chưa ký.
  Future<void> _save(SignatureResult? signed) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(auditFormControllerProvider.notifier);
    final isSuccess = await controller.submitForm(
      scanCode: _scanCodeController.text,
      aiLabel: _aiLabelController.text,
      assetName: _nameController.text,
      quantity: _quantity,
      area: _areaController.text,
      location: _locationController.text,
      condition: _condition.code,
      notes: _notesController.text,
      signatureBytes: signed?.bytes,
      signerName: signed?.signerName,
      signerRole: signed?.signerRole,
      draftId: widget.draftId,
    );

    if (!mounted) return;

    if (isSuccess) {
      showFlSnack(
        context,
        signed == null
            ? 'Đã lưu bản nháp. Phiếu chưa ký nên chưa đồng bộ và chưa vào báo cáo.'
            : 'Đã lưu phiếu kiểm kê trên thiết bị.',
        tone: FlTone.success,
      );
      context.canPop() ? context.pop() : context.go('/');
    } else {
      final errorMsg = ref.read(auditFormControllerProvider).errorMessage;
      showFlSnack(
        context,
        errorMsg ?? 'Không thể lưu bản ghi. Vui lòng thử lại!',
        tone: FlTone.danger,
      );
    }
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(auditFormControllerProvider).isSaving;
    return Form(
      key: _formKey,
      child: ResponsiveLayout.isDesktop(context)
          ? _buildDesktop(isSaving)
          : _buildMobile(isSaving),
    );
  }

  Widget _buildDesktop(bool isSaving) {
    final hasAi = widget.initialAiLabel?.isNotEmpty ?? false;

    final infoCard = FlCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            title: 'Thông tin tài sản',
            subtitle:
                'Phiếu mới • Tạo lúc ${flTime(_createdAt)}, ${flDate(_createdAt)}',
          ),
          const Gap(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'Mã tài sản *',
                  controller: _scanCodeController,
                  validator: (v) => _required(v, 'Vui lòng nhập mã tài sản'),
                  suffix: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'Sao chép mã',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _scanCodeController.text),
                      );
                      showFlSnack(context, 'Đã sao chép mã!');
                    },
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: _Field(
                  label: 'Loại thiết bị *',
                  controller: _aiLabelController,
                  hint: 'Ví dụ: Động cơ điện',
                  validator: (v) => _required(v, 'Vui lòng nhập loại thiết bị'),
                ),
              ),
            ],
          ),
          const Gap(16),
          _Field(
            label: 'Tên tài sản',
            controller: _nameController,
            hint: 'Ví dụ: Động cơ điện Siemens 3 pha',
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Khu vực kiểm kê',
                  controller: _areaController,
                  hint: 'Ví dụ: Xưởng sản xuất A',
                ),
              ),
              const Gap(16),
              Expanded(
                child: _Field(
                  label: 'Vị trí cụ thể',
                  controller: _locationController,
                  hint: 'Ví dụ: Dây chuyền 02 • Kệ A3',
                ),
              ),
            ],
          ),
          const Gap(20),
          const _FieldLabel('Tình trạng thực tế *'),
          Row(
            children: [
              for (final (i, c) in AuditCondition.values.indexed) ...[
                if (i > 0) const Gap(10),
                Expanded(
                  child: _ConditionOption(
                    condition: c,
                    selected: _condition == c,
                    onTap: () => setState(() => _condition = c),
                  ),
                ),
              ],
            ],
          ),
          const Gap(20),
          _Field(
            label: 'Ghi chú hiện trường',
            controller: _notesController,
            hint: 'Bổ sung hiện trạng hoặc sai lệch…',
            maxLines: 3,
            filled: true,
          ),
        ],
      ),
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardHeader(title: 'Số lượng thực tế'),
              const Gap(16),
              _QuantityStepper(
                quantity: _quantity,
                enabled: !isSaving,
                onChanged: _adjustQuantity,
              ),
              const Gap(12),
              _QuickAdd(enabled: !isSaving, onAdd: _adjustQuantity),
              const Gap(14),
              const Text(
                'Số lượng được ghi cùng phiếu và đối chiếu khi đồng bộ.',
                style: TextStyle(fontSize: 11, color: FlColors.primary),
              ),
            ],
          ),
        ),
        const Gap(16),
        FlCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardHeader(title: 'Ảnh minh chứng'),
              const Gap(16),
              _PhotoDrop(onTap: _photoNotReady),
              const Gap(14),
              const Row(
                children: [
                  Icon(Icons.cloud_outlined, size: 16, color: FlColors.muted),
                  Gap(10),
                  Expanded(
                    child: Text(
                      'Ảnh được lưu cùng phiếu trên máy.\nSẵn sàng đồng bộ khi có mạng.',
                      style: TextStyle(
                        fontSize: 11,
                        color: FlColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return DesktopPage(
      heading: DesktopPageHeading(
        title: 'Lập phiếu kiểm kê',
        subtitle: 'Kiểm tra thông tin nhận diện và ghi nhận số lượng thực tế tại hiện trường.',
        action: FilledButton.icon(
          onPressed: isSaving ? null : () => _save(null),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Lưu bản nháp'),
        ),
      ),
      children: [
        if (hasAi) ...[
          const InfoBanner(
            title: 'Thông tin thiết bị đã được điền từ kết quả AI.',
            subtitle: 'Bạn có thể điều chỉnh trước khi lưu phiếu.',
            trailing: StatusPill(label: 'Bản nháp', tone: FlTone.neutral),
          ),
          const Gap(16),
        ],
        FlSplitRow(main: infoCard, side: side, equalHeight: false),
        const Gap(16),
        Row(
          children: [
            OutlinedButton(
              onPressed: isSaving
                  ? null
                  : () => context.canPop() ? context.pop() : context.go('/'),
              child: const Text('Quay lại'),
            ),
            const Gap(24),
            const Icon(Icons.check_rounded, size: 16, color: FlColors.primary),
            const Gap(8),
            const Expanded(
              child: Text(
                'Phiếu được lưu trên máy ngay cả khi không có Internet.',
                style: TextStyle(fontSize: 12, color: FlColors.primary),
              ),
            ),
            FilledButton.icon(
              onPressed: isSaving ? null : _continueToSignature,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.edit_outlined, size: 18),
              label: Text(isSaving ? 'Đang lưu...' : 'Tiếp tục ký xác nhận'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobile(bool isSaving) {
    final title = _nameController.text.isNotEmpty
        ? _nameController.text
        : _aiLabelController.text.isNotEmpty
        ? _aiLabelController.text
        : 'Tài sản chưa nhận diện';

    return MobilePage(
      title: 'Lập phiếu kiểm kê',
      showBack: true,
      trailing: TextButton(
        onPressed: isSaving ? null : () => _save(null),
        child: const Text('Lưu nháp'),
      ),
      belowTitle: const MobileStepBar(
        step: 2,
        total: 3,
        label: 'Ghi nhận thực tế',
      ),
      bottomAction: MobilePrimaryButton(
        label: 'Tiếp tục ký xác nhận',
        loading: isSaving,
        onPressed: _continueToSignature,
      ),
      children: [
        FlCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const IconTile(
                icon: Icons.crop_square_rounded,
                tone: FlTone.info,
                size: 50,
                iconSize: 20,
              ),
              const Gap(13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _scanCodeController.text.isEmpty
                          ? 'Chưa có mã'
                          : _scanCodeController.text,
                      style: const TextStyle(
                        fontSize: 12,
                        color: FlColors.muted,
                      ),
                    ),
                    if (widget.initialAiLabel?.isNotEmpty ?? false) ...[
                      const Gap(6),
                      const StatusPill(label: 'Đã nhận diện AI', bold: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.initialScanCode.isEmpty ||
            (widget.initialAiLabel?.isEmpty ?? true)) ...[
          const Gap(16),
          if (widget.initialScanCode.isEmpty)
            _Field(
              label: 'Mã tài sản *',
              controller: _scanCodeController,
              onChanged: (_) => setState(() {}),
              validator: (v) => _required(v, 'Vui lòng nhập mã tài sản'),
            ),
          if (widget.initialScanCode.isEmpty) const Gap(12),
          _Field(
            label: 'Loại thiết bị *',
            controller: _aiLabelController,
            hint: 'Ví dụ: Máy khoan',
            onChanged: (_) => setState(() {}),
            validator: (v) => _required(v, 'Vui lòng nhập loại thiết bị'),
          ),
        ],
        const Gap(16),
        _Field(
          label: 'Tên tài sản',
          controller: _nameController,
          hint: 'Ví dụ: Động cơ điện Siemens 3 pha',
          onChanged: (_) => setState(() {}),
        ),
        const Gap(16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Field(
                label: 'Khu vực kiểm kê',
                controller: _areaController,
                hint: 'Khu vực A',
              ),
            ),
            const Gap(10),
            Expanded(
              child: _Field(
                label: 'Vị trí cụ thể',
                controller: _locationController,
                hint: 'Kệ A3',
              ),
            ),
          ],
        ),
        const Gap(22),
        const _MobileTitle('Số lượng thực tế'),
        _QuantityStepper(
          quantity: _quantity,
          enabled: !isSaving,
          onChanged: _adjustQuantity,
          surface: FlColors.surface,
        ),
        const Gap(18),
        const SectionLabel('Thêm nhanh'),
        const Gap(8),
        _QuickAdd(enabled: !isSaving, onAdd: _adjustQuantity, compact: true),
        const Gap(22),
        const _MobileTitle('Tình trạng thiết bị'),
        Row(
          children: [
            for (final (i, c) in AuditCondition.values.indexed) ...[
              if (i > 0) const Gap(8),
              Expanded(
                child: _MobileConditionChip(
                  condition: c,
                  selected: _condition == c,
                  onTap: () => setState(() => _condition = c),
                ),
              ),
            ],
          ],
        ),
        const Gap(22),
        const _MobileTitle('Ghi chú hiện trường'),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Bổ sung hiện trạng hoặc sai lệch…',
          ),
        ),
        const Gap(14),
        OutlinedButton.icon(
          onPressed: _photoNotReady,
          style: OutlinedButton.styleFrom(
            foregroundColor: FlColors.primary,
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(44),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Thêm ảnh minh chứng',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _photoNotReady() => showFlSnack(
    context,
    'Đính kèm ảnh minh chứng sẽ có trong bản cập nhật tới.',
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: FlColors.muted),
      ),
    );
  }
}

class _MobileTitle extends StatelessWidget {
  const _MobileTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.suffix,
    this.maxLines = 1,
    this.filled = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final Widget? suffix;
  final int maxLines;
  final bool filled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          onChanged: onChanged,
          // Phím Return chuyển sang ô kế tiếp thay vì đứng yên.
          textInputAction: maxLines == 1 ? TextInputAction.next : null,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            fillColor: filled ? FlColors.surfaceAlt : FlColors.surface,
          ),
        ),
      ],
    );
  }
}

class _ConditionOption extends StatelessWidget {
  const _ConditionOption({
    required this.condition,
    required this.selected,
    required this.onTap,
  });

  final AuditCondition condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = condition.tone;
    return Material(
      color: selected ? tone.background : FlColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlRadius.control),
        side: BorderSide(
          color: selected
              ? tone.foreground.withValues(alpha: 0.4)
              : FlColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FlRadius.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              if (selected) ...[
                Icon(Icons.circle, size: 9, color: tone.foreground),
                const Gap(8),
              ],
              Flexible(
                child: Text(
                  condition.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? tone.foreground : FlColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileConditionChip extends StatelessWidget {
  const _MobileConditionChip({
    required this.condition,
    required this.selected,
    required this.onTap,
  });

  final AuditCondition condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = condition.tone;
    return Material(
      color: selected ? tone.background : FlColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? Colors.transparent : FlColors.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                Icon(Icons.circle, size: 7, color: tone.foreground),
                const Gap(5),
              ],
              Flexible(
                child: Text(
                  condition.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? tone.foreground : FlColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.enabled,
    required this.onChanged,
    this.surface = FlColors.background,
  });

  final int quantity;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, int delta, {bool accent = false}) {
      return SizedBox(
        width: 46,
        height: 38,
        child: Material(
          color: accent ? FlColors.primarySoft : FlColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FlRadius.control),
            side: BorderSide(
              color: accent ? Colors.transparent : FlColors.border,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(FlRadius.control),
            onTap: enabled ? () => onChanged(delta) : null,
            child: Icon(
              icon,
              size: 18,
              color: accent ? FlColors.primary : FlColors.ink,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(FlRadius.control),
        border: surface == FlColors.surface
            ? Border.all(color: FlColors.border)
            : null,
      ),
      child: Row(
        children: [
          button(Icons.remove_rounded, -1),
          Expanded(
            child: Text(
              quantity.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          button(Icons.add_rounded, 1, accent: surface == FlColors.surface),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({
    required this.enabled,
    required this.onAdd,
    this.compact = false,
  });

  final bool enabled;
  final ValueChanged<int> onAdd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, n) in const [1, 5, 10].indexed) ...[
          if (i > 0) const Gap(8),
          Expanded(
            child: OutlinedButton(
              onPressed: enabled ? () => onAdd(n) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: compact ? FlColors.primary : FlColors.ink,
                backgroundColor: compact
                    ? FlColors.surfaceAlt
                    : FlColors.surface,
              ),
              child: Text('+$n'),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoDrop extends StatelessWidget {
  const _PhotoDrop({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FlColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlRadius.control),
        side: const BorderSide(color: FlColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FlRadius.control),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Column(
            children: [
              Icon(
                Icons.center_focus_strong_outlined,
                size: 18,
                color: FlColors.primary,
              ),
              Gap(10),
              Text(
                'Thêm ảnh hiện trường',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FlColors.primary,
                ),
              ),
              Gap(4),
              Text(
                'JPG, PNG • Tối đa 10 MB/ảnh',
                style: TextStyle(fontSize: 11, color: FlColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
