import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

import '../data/repair_rate_repository.dart';
import '../domain/entities/damage_enums.dart';
import '../domain/entities/repair_rate.dart';
import '../domain/entities/surface_assessment.dart';
import 'damage_format.dart';
import 'surface_assessment_draft.dart';

/// Phần "Đánh giá hư hỏng bề mặt" của phiếu kiểm kê: chất liệu, diện tích,
/// các vùng hư hỏng (AI đo hoặc nhập tay) và chi phí ước tính.
class SurfaceAssessmentSection extends ConsumerStatefulWidget {
  const SurfaceAssessmentSection({
    super.key,
    required this.draft,
    this.enabled = true,
    this.onAssessmentChanged,
  });

  final SurfaceAssessmentDraft draft;
  final bool enabled;

  /// Gọi khi kết quả tính thay đổi (để phiếu gợi ý tình trạng).
  final ValueChanged<SurfaceAssessment?>? onAssessmentChanged;

  @override
  ConsumerState<SurfaceAssessmentSection> createState() =>
      _SurfaceAssessmentSectionState();
}

class _SurfaceAssessmentSectionState
    extends ConsumerState<SurfaceAssessmentSection> {
  final _areaController = TextEditingController();
  final _rowControllers = <DamageRowDraft, TextEditingController>{};
  SurfaceAssessment? _lastReported;
  bool _reported = false;

  SurfaceAssessmentDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _areaController.text = _draft.surfaceAreaText;
    _draft.addListener(_onDraftChanged);
  }

  @override
  void didUpdateWidget(SurfaceAssessmentSection old) {
    super.didUpdateWidget(old);
    if (old.draft != widget.draft) {
      old.draft.removeListener(_onDraftChanged);
      widget.draft.addListener(_onDraftChanged);
    }
  }

  @override
  void dispose() {
    _draft.removeListener(_onDraftChanged);
    _areaController.dispose();
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onDraftChanged() {
    // Đồng bộ ô nhập khi draft được điền từ ngoài (bản nháp, danh mục).
    if (_areaController.text != _draft.surfaceAreaText) {
      _areaController.text = _draft.surfaceAreaText;
    }
    for (final row in _draft.rows) {
      final c = _rowControllers[row];
      if (c != null && c.text != row.quantityText) c.text = row.quantityText;
    }
    _rowControllers.removeWhere((row, c) {
      if (_draft.rows.contains(row)) return false;
      c.dispose();
      return true;
    });
    if (mounted) setState(() {});
  }

  TextEditingController _controllerFor(DamageRowDraft row) => _rowControllers
      .putIfAbsent(row, () => TextEditingController(text: row.quantityText));

  void _report(SurfaceAssessment? a) {
    if (_reported && a == _lastReported) return;
    _reported = true;
    _lastReported = a;
    final cb = widget.onAssessmentChanged;
    if (cb != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) cb(a);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculator = ref.watch(damageCalculatorProvider);
    final table = ref.watch(repairRateTableProvider).value;
    final assessment = calculator.whenOrNull(data: _draft.assess);
    _report(assessment);
    final error = _draft.isUsed ? _draft.validate() : null;

    return Column(
      key: const Key('surface-assessment'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              // Dựng lại ô chọn khi chất liệu đổi từ ngoài (mở bản nháp).
              child: KeyedSubtree(
                key: ValueKey(_draft.material),
                child: DropdownButtonFormField<SurfaceMaterial>(
                  key: const Key('surface-material'),
                  initialValue: _draft.material,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Chất liệu'),
                  items: [
                    for (final m in SurfaceMaterial.values)
                      DropdownMenuItem(value: m, child: Text(m.label)),
                  ],
                  onChanged: widget.enabled
                      ? (m) => m == null ? null : _draft.setMaterial(m)
                      : null,
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: TextField(
                key: const Key('surface-area'),
                controller: _areaController,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInput],
                decoration: const InputDecoration(
                  labelText: 'Diện tích bề mặt',
                  suffixText: 'm²',
                ),
                onChanged: _draft.setSurfaceArea,
              ),
            ),
          ],
        ),
        if (_draft.capturedAreaM2 != null &&
            _draft.surfaceAreaText.trim().isEmpty) ...[
          const Gap(6),
          Text(
            'Vùng chụp ≈ ${formatQuantity(_draft.capturedAreaM2!, MeasureUnit.squareMeter)}. '
            'Nhập diện tích cả bề mặt (tường, trần…) để chỉ số chính xác.',
            style: const TextStyle(fontSize: 12, color: FlColors.muted),
          ),
        ],
        const Gap(14),
        for (final row in _draft.rows) ...[
          _DamageRow(
            key: ObjectKey(row),
            row: row,
            controller: _controllerFor(row),
            enabled: widget.enabled,
            onType: (t) => _draft.updateRow(row, type: t),
            onQuantity: (q) => _draft.updateRow(row, quantity: q),
            onRemove: () => _draft.removeRow(row),
          ),
          const Gap(10),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<DamageType>(
            key: const Key('add-damage'),
            enabled: widget.enabled,
            onSelected: _draft.addRow,
            itemBuilder: (_) => [
              for (final t in DamageType.values)
                PopupMenuItem(value: t, child: Text(t.label)),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: FlColors.primary),
                  Gap(6),
                  Text(
                    'Thêm hư hỏng',
                    style: TextStyle(
                      color: FlColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const Gap(8),
          Text(
            error,
            key: const Key('assessment-error'),
            style: const TextStyle(fontSize: 12, color: FlColors.danger),
          ),
        ],
        if (assessment != null) ...[
          const Gap(12),
          _AssessmentSummary(assessment: assessment, table: table),
        ] else if (_draft.isUsed && error == null && calculator.isLoading) ...[
          const Gap(12),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }
}

final _decimalInput = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

class _DamageRow extends StatelessWidget {
  const _DamageRow({
    super.key,
    required this.row,
    required this.controller,
    required this.enabled,
    required this.onType,
    required this.onQuantity,
    required this.onRemove,
  });

  final DamageRowDraft row;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<DamageType> onType;
  final ValueChanged<String> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final conf = row.confidence;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: DropdownButtonFormField<DamageType>(
            initialValue: row.type,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Loại hư hỏng',
              helperText: conf == null
                  ? 'Nhập tay'
                  : 'AI ${(conf * 100).round()}%',
            ),
            items: [
              for (final t in DamageType.values)
                DropdownMenuItem(value: t, child: Text(t.shortLabel)),
            ],
            onChanged: enabled ? (t) => t == null ? null : onType(t) : null,
          ),
        ),
        const Gap(10),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalInput],
            decoration: InputDecoration(
              labelText: row.type.unit == MeasureUnit.meter
                  ? 'Dài'
                  : 'Diện tích',
              suffixText: row.type.unit.symbol,
            ),
            onChanged: onQuantity,
          ),
        ),
        IconButton(
          tooltip: 'Xoá',
          onPressed: enabled ? onRemove : null,
          icon: const Icon(Icons.close_rounded, color: FlColors.muted),
        ),
      ],
    );
  }
}

class _AssessmentSummary extends StatelessWidget {
  const _AssessmentSummary({required this.assessment, required this.table});

  final SurfaceAssessment assessment;
  final RepairRateTable? table;

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    return Container(
      key: const Key('assessment-summary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FlColors.surfaceAlt,
        borderRadius: BorderRadius.circular(FlRadius.control),
        border: Border.all(color: FlColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final i in a.items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    i.type.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusPill(
                  label: '${i.severity.label} · ${i.damageIndex.round()}',
                  tone: _tone(i.severity),
                ),
              ],
            ),
            const Gap(4),
            Text(
              i.hasPrice
                  ? '${formatQuantity(i.billedQuantity, i.type.unit)} × '
                        '${formatVnd(i.unitPrice!)} = ${formatVnd(i.estimatedCost!)}'
                  : 'Chưa có đơn giá cho mức này',
              style: TextStyle(
                fontSize: 12,
                color: i.hasPrice ? FlColors.muted : FlColors.warning,
              ),
            ),
            if (i.fullSurface)
              const Text(
                'Hư hỏng lan rộng: tính xử lý toàn bộ bề mặt',
                style: TextStyle(fontSize: 12, color: FlColors.warning),
              ),
            if (i.method.isNotEmpty)
              Text(
                i.method,
                style: const TextStyle(fontSize: 12, color: FlColors.muted),
              ),
            const Gap(10),
          ],
          if (a.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('Không ghi nhận hư hỏng trên bề mặt này.'),
            ),
          const Divider(height: 1),
          const Gap(10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi phí ước tính',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                formatVnd(a.totalCost),
                key: const Key('assessment-total'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: FlColors.primary,
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            'Điểm tình trạng bề mặt: ${a.conditionScore.round()}/100',
            style: const TextStyle(fontSize: 12, color: FlColors.muted),
          ),
          if (a.unpricedCount > 0)
            Text(
              '${a.unpricedCount} hạng mục chưa có đơn giá, chưa tính vào tổng.',
              style: const TextStyle(fontSize: 12, color: FlColors.warning),
            ),
          if (a.usesSampleRates)
            const Text(
              'Đang dùng bảng giá minh hoạ, chưa phải giá thật của nhà trường.',
              style: TextStyle(fontSize: 12, color: FlColors.warning),
            ),
          if (table != null && table!.source == RepairRateSource.cache)
            const Text(
              'Ngoại tuyến: dùng bảng giá đã lưu lần trước.',
              style: TextStyle(fontSize: 12, color: FlColors.muted),
            ),
        ],
      ),
    );
  }

  static FlTone _tone(DamageSeverity s) => switch (s) {
    DamageSeverity.light => FlTone.info,
    DamageSeverity.moderate => FlTone.warning,
    DamageSeverity.severe => FlTone.danger,
  };
}
