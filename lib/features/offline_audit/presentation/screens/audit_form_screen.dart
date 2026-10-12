import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../controllers/audit_form_controller.dart';

/// Màn hình Biểu mẫu kiểm kê động (Dynamic Form) cho tính năng Offline Audit.
///
/// Nhận dữ liệu quét mã từ camera scanner và nhãn do On-Device AI nhận diện,
/// cho phép người kiểm kê xác nhận thông tin, nhập số lượng và ký xác nhận trước khi lưu.
class AuditFormScreen extends ConsumerStatefulWidget {
  final String initialScanCode;
  final String? initialAiLabel;

  const AuditFormScreen({
    super.key,
    required this.initialScanCode,
    this.initialAiLabel,
  });

  @override
  ConsumerState<AuditFormScreen> createState() => _AuditFormScreenState();
}

class _AuditFormScreenState extends ConsumerState<AuditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scanCodeController;
  late final TextEditingController _aiLabelController;
  late final TextEditingController _quantityController;
  Uint8List? _signatureBytes;

  /// Điều hướng sang màn hình ký xác nhận và nhận dữ liệu PNG bytes trả về
  Future<void> _handleCaptureSignature() async {
    final result = await context.push<Uint8List?>('/signature');
    if (result != null && mounted) {
      setState(() {
        _signatureBytes = result;
      });
    }
  }

  /// Xóa chữ ký đã đính kèm
  void _handleClearSignature() {
    setState(() {
      _signatureBytes = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _scanCodeController = TextEditingController(text: widget.initialScanCode);
    _aiLabelController = TextEditingController(
      text: widget.initialAiLabel ?? '',
    );
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _scanCodeController.dispose();
    _aiLabelController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Tăng/giảm số lượng thông qua các nút thao tác nhanh
  void _adjustQuantity(int delta) {
    final current = int.tryParse(_quantityController.text) ?? 1;
    final next = (current + delta).clamp(1, 999999);
    _quantityController.text = next.toString();
  }

  /// Xử lý gửi biểu mẫu và lưu vào database
  Future<void> _handleSubmit() async {
    // Ẩn bàn phím trước khi lưu
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    final controller = ref.read(auditFormControllerProvider.notifier);

    final isSuccess = await controller.submitForm(
      scanCode: widget.initialScanCode,
      aiLabel: widget.initialAiLabel,
      quantity: quantity,
      signatureBytes: _signatureBytes,
    );

    if (!mounted) return;

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              Gap(10),
              Expanded(
                child: Text(
                  'Đã lưu bản ghi kiểm kê thành công vào thiết bị!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (context.canPop()) {
        context.pop();
      }
    } else {
      final errorMsg = ref.read(auditFormControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const Gap(10),
              Expanded(
                child: Text(
                  errorMsg ?? 'Không thể lưu bản ghi. Vui lòng thử lại!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(auditFormControllerProvider);
    final theme = Theme.of(context);
    final isSaving = formState.isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Biểu mẫu kiểm kê',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner thông tin Offline-First
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.offline_bolt_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chế độ Ngoại tuyến (Offline-First)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              'Dữ liệu được lưu trữ an toàn trên thiết bị và sẽ tự động đồng bộ khi có mạng.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // Card chứa thông tin mã thiết bị / QR
                Text(
                  'Thông tin thiết bị',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(12),

                // Trường 1: Mã thiết bị / QR (Read-only)
                TextFormField(
                  controller: _scanCodeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Mã thiết bị / QR',
                    hintText: 'Chưa có mã',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'Sao chép mã',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _scanCodeController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép mã!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(16),

                // Trường 2: AI Nhận diện (Read-only)
                TextFormField(
                  controller: _aiLabelController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'AI Nhận diện đối tượng',
                    hintText: 'Không có nhãn nhận diện',
                    prefixIcon: Icon(
                      Icons.auto_awesome_rounded,
                      color: widget.initialAiLabel != null
                          ? Colors.amber.shade700
                          : theme.colorScheme.outline,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.initialAiLabel != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
                const Gap(24),

                // Card nhập số lượng
                Text(
                  'Chi tiết kiểm kê',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(12),

                // Trường 3: Số lượng (Bắt buộc nhập, bàn phím số, mặc định 1)
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Số lượng *',
                    hintText: 'Nhập số lượng',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          tooltip: 'Giảm 1',
                          onPressed: isSaving ? null : () => _adjustQuantity(-1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          tooltip: 'Tăng 1',
                          onPressed: isSaving ? null : () => _adjustQuantity(1),
                        ),
                        const Gap(4),
                      ],
                    ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số lượng kiểm kê';
                    }
                    final qty = int.tryParse(value.trim());
                    if (qty == null) {
                      return 'Số lượng không hợp lệ';
                    }
                    if (qty <= 0) {
                      return 'Số lượng phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const Gap(12),

                // Quick quantity adjust chips
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('+1'),
                      onPressed: isSaving ? null : () => _adjustQuantity(1),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('+5'),
                      onPressed: isSaving ? null : () => _adjustQuantity(5),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('+10'),
                      onPressed: isSaving ? null : () => _adjustQuantity(10),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.refresh, size: 16),
                      label: const Text('Đặt lại = 1'),
                      onPressed: isSaving
                          ? null
                          : () => _quantityController.text = '1',
                    ),
                  ],
                ),
                const Gap(24),

                // Card chữ ký xác nhận / Chú thích
                Text(
                  'Chữ ký xác nhận',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(12),
                if (_signatureBytes == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.draw_outlined,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                        const Gap(10),
                        Text(
                          'Chưa có chữ ký xác nhận',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Ký tên hoặc vẽ chú thích để xác nhận tình trạng kiểm kê',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Gap(16),
                        OutlinedButton.icon(
                          onPressed: isSaving ? null : _handleCaptureSignature,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Ký xác nhận kiểm kê'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade600,
                                size: 18,
                              ),
                              const Gap(8),
                              Text(
                                'Đã đính kèm chữ ký xác nhận',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Image.memory(
                              _signatureBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const Gap(10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed:
                                    isSaving ? null : _handleCaptureSignature,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Ký lại'),
                              ),
                              const Gap(8),
                              TextButton.icon(
                                onPressed:
                                    isSaving ? null : _handleClearSignature,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Xóa chữ ký',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const Gap(32),

                // Nút "Lưu kiểm kê"
                FilledButton.icon(
                  onPressed: isSaving ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    isSaving ? 'Đang lưu bản ghi...' : 'Lưu kiểm kê',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(12),

                // Nút Huỷ / Quay lại
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Huỷ bỏ'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
