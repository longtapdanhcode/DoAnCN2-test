import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';

/// Thông tin phiếu được truyền từ màn lập phiếu sang màn ký.
class AuditSummary {
  const AuditSummary({
    required this.scanCode,
    required this.label,
    required this.name,
    required this.area,
    this.location = '',
    required this.quantity,
    required this.condition,
    required this.conditionTone,
    required this.createdAt,
  });

  final String scanCode;
  final String label;
  final String name;
  final String area;
  final String location;
  final int quantity;
  final String condition;
  final FlTone conditionTone;
  final DateTime createdAt;

  String get displayName => name.isNotEmpty ? name : label;
}

/// Kết quả trả về từ màn ký: ảnh chữ ký PNG và người ký.
class SignatureResult {
  const SignatureResult({
    required this.bytes,
    required this.signerName,
    required this.signerRole,
  });

  final Uint8List bytes;
  final String signerName;
  final String signerRole;
}

/// Màn hình Ký xác nhận kiểm kê (Figma 05 / M04).
///
/// Cho phép người dùng ký xác nhận kiểm kê, sau đó xuất ra dữ liệu ảnh PNG
/// dạng byte array kèm họ tên, vai trò người ký ([SignatureResult]) trả về màn
/// hình lập phiếu để lưu cùng bản ghi.
class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key, this.summary});

  final AuditSummary? summary;

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  late final SignatureController _controller;
  // Điền sẵn họ tên và vai trò của tài khoản đang đăng nhập; vẫn sửa được
  // khi người ký là người khác.
  late final _nameController = TextEditingController(
    text: ref.read(signedInUserProvider)?.displayName ?? '',
  );
  late final _roleController = TextEditingController(
    text: ref.read(signedInUserProvider)?.role.label ?? 'Kiểm kê viên',
  );

  String get _auditorName => ref.read(signedInUserProvider)?.displayName ?? '';
  bool _isExporting = false;
  bool _confirmed = true;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.5,
      penColor: FlColors.ink,
      exportBackgroundColor: Colors.white,
    )..addListener(_onStroke);
  }

  @override
  void dispose() {
    // Đảm bảo dispose controller để tránh rò rỉ bộ nhớ
    _controller
      ..removeListener(_onStroke)
      ..dispose();
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _onStroke() {
    // Cập nhật gợi ý "Chạm và kéo để ký" khi canvas đổi trạng thái trống/có nét.
    if (mounted) setState(() {});
  }

  /// Xoá toàn bộ nét vẽ trên canvas
  void _handleClear() {
    _controller.clear();
    setState(() {});
  }

  /// Xuất ảnh chữ ký ra định dạng PNG byte array và trả về màn hình trước
  Future<void> _handleConfirm() async {
    if (_controller.isEmpty) {
      showFlSnack(
        context,
        'Vui lòng ký tên trước khi hoàn tất!',
        tone: FlTone.warning,
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      showFlSnack(
        context,
        'Vui lòng nhập họ tên người xác nhận.',
        tone: FlTone.warning,
      );
      return;
    }
    if (!_confirmed) {
      showFlSnack(
        context,
        'Vui lòng xác nhận thông tin kiểm kê là chính xác.',
        tone: FlTone.warning,
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final Uint8List? bytes = await _controller.toPngBytes();

      if (!mounted) return;

      if (bytes != null && bytes.isNotEmpty) {
        context.pop(
          SignatureResult(
            bytes: bytes,
            signerName: _nameController.text.trim(),
            signerRole: _roleController.text.trim(),
          ),
        );
      } else {
        showFlSnack(
          context,
          'Không thể xuất dữ liệu chữ ký. Vui lòng thử lại!',
          tone: FlTone.danger,
        );
      }
    } catch (e) {
      if (mounted) {
        showFlSnack(
          context,
          'Đã xảy ra lỗi khi lưu chữ ký: $e',
          tone: FlTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout.isDesktop(context)
        ? _buildDesktop()
        : _buildMobile();
  }

  Widget _canvas({required double height, required bool showLabel}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: FlColors.surface,
        borderRadius: BorderRadius.circular(FlRadius.card),
        border: Border.all(color: FlColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (showLabel)
            const Positioned(
              left: 20,
              top: 18,
              child: SectionLabel('Khu vực ký tên'),
            ),
          if (_controller.isEmpty)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.draw_outlined, size: 36, color: FlColors.border),
                  Gap(12),
                  Text(
                    'Chạm và kéo để ký',
                    style: TextStyle(fontSize: 14, color: FlColors.muted),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 26,
            right: 26,
            bottom: 36,
            child: Container(height: 1, color: FlColors.border),
          ),
          Positioned.fill(
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    final s = widget.summary;

    final summaryCard = FlCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'Tóm tắt phiếu kiểm kê'),
          const Gap(20),
          const StatusPill(label: 'Phiếu mới', tone: FlTone.info),
          const Gap(12),
          KeyValueRow(label: 'Tài sản', value: _value(s?.displayName)),
          KeyValueRow(label: 'Mã tài sản', value: _value(s?.scanCode)),
          KeyValueRow(label: 'Khu vực', value: _value(s?.area)),
          KeyValueRow(label: 'Vị trí cụ thể', value: _value(s?.location)),
          KeyValueRow(
            label: 'Số lượng thực tế',
            value: _value(s == null ? null : '${s.quantity} thiết bị'),
          ),
          KeyValueRow(label: 'Người kiểm kê', value: _value(_auditorName)),
          KeyValueRow(
            label: 'Thời gian',
            value: _value(
              s == null
                  ? null
                  : '${flDate(s.createdAt)} • ${flTime(s.createdAt)}',
            ),
          ),
          if (s != null) ...[
            const Gap(24),
            StatusPill(label: s.condition, tone: s.conditionTone),
          ],
        ],
      ),
    );

    final signatureCard = FlCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            title: 'Chữ ký người xác nhận',
            subtitle: 'Dùng chuột hoặc bút cảm ứng để ký trong khung bên dưới.',
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: _LabeledInput(
                  label: 'Họ và tên người xác nhận *',
                  controller: _nameController,
                ),
              ),
              const Gap(24),
              Expanded(
                child: _LabeledInput(
                  label: 'Vai trò',
                  controller: _roleController,
                ),
              ),
            ],
          ),
          const Gap(24),
          _canvas(height: 250, showLabel: true),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isExporting ? null : _handleClear,
              child: const Text('Xóa và ký lại'),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
              ),
              const Gap(4),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tôi xác nhận thông tin và số lượng kiểm kê là chính xác.',
                        style: TextStyle(fontSize: 13),
                      ),
                      Gap(10),
                      Text(
                        'Chữ ký được đính kèm trong phiếu và báo cáo PDF.',
                        style: TextStyle(fontSize: 11, color: FlColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return DesktopPage(
      heading: const DesktopPageHeading(
        title: 'Ký xác nhận kiểm kê',
        subtitle: 'Rà soát phiếu và ký xác nhận trước khi hoàn tất ghi nhận.',
      ),
      children: [
        const _Stepper(),
        const Gap(24),
        FlSplitRow(
          main: summaryCard,
          side: signatureCard,
          flex: 4,
          equalHeight: false,
        ),
        const Gap(24),
        Row(
          children: [
            const Expanded(
              flex: 7,
              child: InfoBanner(
                title: 'Phiếu được lưu trên máy ngay cả khi không có Internet.',
              ),
            ),
            const Gap(24),
            Expanded(
              flex: 4,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _handleConfirm,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _isExporting ? 'Đang lưu...' : 'Hoàn tất & lưu phiếu kiểm kê',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobile() {
    final s = widget.summary;
    return MobilePage(
      title: 'Ký xác nhận',
      showBack: true,
      belowTitle: const MobileStepBar(
        step: 3,
        total: 3,
        label: 'Xác nhận phiếu',
      ),
      bottomAction: MobilePrimaryButton(
        label: 'Hoàn tất kiểm kê',
        loading: _isExporting,
        onPressed: _handleConfirm,
      ),
      children: [
        FlCard(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(s?.scanCode ?? 'Phiếu mới'),
                    const Gap(8),
                    Text(
                      s?.displayName.isNotEmpty ?? false
                          ? s!.displayName
                          : 'Phiếu kiểm kê',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Người kiểm kê: $_auditorName',
                      style: TextStyle(fontSize: 12, color: FlColors.muted),
                    ),
                  ],
                ),
              ),
              if (s != null)
                StatusPill(label: '${s.quantity} thiết bị', bold: true),
            ],
          ),
        ),
        const Gap(22),
        const Text(
          'Chữ ký người xác nhận',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Gap(6),
        const Text(
          'Ký trực tiếp vào vùng bên dưới',
          style: TextStyle(fontSize: 12, color: FlColors.muted),
        ),
        const Gap(14),
        _canvas(height: 215, showLabel: false),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isExporting ? null : _handleClear,
            child: const Text(
              'Xóa chữ ký',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _LabeledInput(
          label: 'Họ tên người xác nhận',
          controller: _nameController,
          strongLabel: true,
        ),
        const Gap(14),
        const InfoBanner(title: 'Biên bản được lưu cùng chữ ký điện tử'),
      ],
    );
  }

  Widget _value(String? text) => Text(
    (text == null || text.isEmpty) ? '—' : text,
    style: const TextStyle(fontSize: 13),
  );
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    this.strongLabel = false,
  });

  final String label;
  final TextEditingController controller;
  final bool strongLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: strongLabel
              ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
              : const TextStyle(fontSize: 12, color: FlColors.muted),
        ),
        const Gap(8),
        TextField(controller: controller, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

/// Thanh 3 bước của luồng lập phiếu trên desktop.
class _Stepper extends StatelessWidget {
  const _Stepper();

  @override
  Widget build(BuildContext context) {
    Widget step(String label, {required bool done, String? number}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: done ? FlColors.primarySoft : FlColors.primary,
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: FlColors.primary,
                )
              : Text(
                  number!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const Gap(14),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: done ? FlColors.muted : FlColors.ink,
            ),
          ),
        ),
      ],
    );

    Widget segment(String label) => Expanded(
      child: Row(
        children: [
          Flexible(child: step(label, done: true)),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          segment('Thông tin tài sản'),
          segment('Kiểm kê thực tế'),
          Expanded(child: step('Ký xác nhận', done: false, number: '3')),
        ],
      ),
    );
  }
}
