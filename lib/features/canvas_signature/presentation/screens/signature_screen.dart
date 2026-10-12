import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

/// Màn hình vẽ chữ ký số & ghi chú chú thích ảnh bằng Custom Canvas.
///
/// Cho phép người dùng ký xác nhận kiểm kê hoặc khoanh vùng chú thích lỗi thiết bị,
/// sau đó xuất ra dữ liệu ảnh PNG dạng byte array [Uint8List] để đính kèm vào bản ghi.
class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late final SignatureController _controller;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller với màu bút đen, nét vẽ 3, màu nền xám nhạt
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    // Đảm bảo dispose controller để tránh rò rỉ bộ nhớ
    _controller.dispose();
    super.dispose();
  }

  /// Xoá toàn bộ nét vẽ trên canvas
  void _handleClear() {
    _controller.clear();
    setState(() {});
  }

  /// Xuất ảnh chữ ký ra định dạng PNG byte array và trả về màn hình trước
  Future<void> _handleConfirm() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              Gap(10),
              Expanded(
                child: Text('Vui lòng ký tên hoặc vẽ chú thích trước khi xác nhận!'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final Uint8List? bytes = await _controller.toPngBytes();

      if (!mounted) return;

      if (bytes != null && bytes.isNotEmpty) {
        context.pop(bytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xuất dữ liệu chữ ký. Vui lòng thử lại!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi lưu chữ ký: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ký xác nhận kiểm kê',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xóa nét vẽ',
            onPressed: _handleClear,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
          children: [
            // Hướng dẫn ký tên
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.gesture_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const Gap(8),
                  Text(
                    'Ký tên hoặc vẽ chú thích vào khung bên dưới',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Vùng Custom Canvas (Signature widget)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), // Nền xám nhạt
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxStyle.boxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      // Đường kẻ ký tên nét đứt ở 1/3 dưới
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 48,
                        child: Row(
                          children: [
                            Text(
                              'X',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Canvas chữ ký
                      Signature(
                        controller: _controller,
                        backgroundColor: const Color(0xFFF3F4F6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Thanh điều khiển dưới đáy
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Nút "Xóa lại"
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : _handleClear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Xóa lại'),
                    ),
                  ),
                  const Gap(12),

                  // Nút "Xác nhận"
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _handleConfirm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isExporting ? 'Đang lưu...' : 'Xác nhận chữ ký',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class BoxStyle {
  static BoxShadow boxShadow({
    required Color color,
    required double blurRadius,
    required Offset offset,
  }) {
    return BoxShadow(
      color: color,
      blurRadius: blurRadius,
      offset: offset,
    );
  }
}
