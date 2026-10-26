import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

import '../../domain/entities/scan_result.dart';
import '../controllers/scanner_controller.dart';
import '../widgets/scanner_overlay.dart';

/// Nhãn AI đã tách phần trăm độ tin cậy, ví dụ "Động cơ điện (96.8%)".
class _AiGuess {
  const _AiGuess(this.label, this.confidence);

  final String label;
  final double? confidence;

  static _AiGuess? parse(List<String> objects) {
    if (objects.isEmpty) return null;
    final raw = objects.first;
    final match = RegExp(r'^(.*)\s\((\d+(?:\.\d+)?)%\)$').firstMatch(raw);
    if (match == null) return _AiGuess(raw, null);
    return _AiGuess(match.group(1)!, double.parse(match.group(2)!) / 100);
  }

  String get percent =>
      '${((confidence ?? 0) * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
}

/// Màn hình Quét mã & nhận diện AI (Figma 03 / M02).
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  bool _isNavigating = false;
  DateTime? _lastNavigationTime;
  bool _aiMode = true;

  /// Điều hướng sang màn hình Biểu mẫu kiểm kê với cơ chế debounce
  void _navigateToAuditForm(String scanCode, String? aiLabel) {
    final now = DateTime.now();
    if (_isNavigating) return;
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!).inMilliseconds < 1500) {
      return;
    }

    _isNavigating = true;
    _lastNavigationTime = now;

    context
        .push('/audit-form', extra: {'scanCode': scanCode, 'aiLabel': aiLabel})
        .then((_) {
          _isNavigating = false;
          if (mounted) {
            ref.read(scannerControllerProvider.notifier).resumeScanning();
          }
        });
  }

  /// Xác nhận kết quả hiện tại và chuyển sang lập phiếu.
  void _confirmResult(ScannerUiState uiState) {
    final result = uiState.latestResult;
    final guess = _AiGuess.parse(uiState.detectedObjects);
    if (result == null && guess == null) {
      showFlSnack(context, 'Chưa có kết quả. Đưa mã hoặc thiết bị vào khung.');
      return;
    }
    final code = result == null
        ? ''
        : (result.rawValue.isNotEmpty ? result.rawValue : result.displayValue);
    _navigateToAuditForm(code, guess?.label);
  }

  /// Nhập mã tài sản bằng tay khi không quét được.
  Future<void> _enterCodeManually() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _ManualCodeDialog(),
    );
    if (code != null && code.trim().isNotEmpty && mounted) {
      _navigateToAuditForm(code.trim(), null);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Gọi initialize() một cách rõ ràng sau frame đầu tiên để controller.start() chạy khi view đã mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(scannerControllerProvider.notifier).initialize();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final notifier = ref.read(scannerControllerProvider.notifier);

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        notifier.onAppInactive();
        break;
      case AppLifecycleState.resumed:
        notifier.onAppResumed();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(scannerControllerProvider);
    final scannerRepo = ref.watch(scannerRepositoryProvider);
    final camera = _CameraBox(
      uiState: uiState,
      controller: scannerRepo.controller,
      aiMode: _aiMode,
      showControls: !ResponsiveLayout.isDesktop(context),
      onManualEntry: _enterCodeManually,
    );

    return ResponsiveLayout.isDesktop(context)
        ? _buildDesktop(uiState, camera)
        : _buildMobile(uiState, camera);
  }

  Widget _buildDesktop(ScannerUiState uiState, Widget camera) {
    final notifier = ref.read(scannerControllerProvider.notifier);
    final scanning = uiState.status == ScannerStatus.scanning;

    final cameraCard = FlCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            title: 'Camera hiện trường',
            trailing: StatusPill(label: 'AI trên thiết bị'),
          ),
          const Gap(16),
          _ModeSwitch(
            aiMode: _aiMode,
            onChanged: (v) => setState(() => _aiMode = v),
          ),
          const Gap(16),
          SizedBox(height: 420, child: camera),
          const Gap(16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed: notifier.switchCamera,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Đổi camera'),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                flex: 3,
                child: OutlinedButton(
                  onPressed: notifier.toggleTorch,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(uiState.isTorchOn ? 'Tắt đèn' : 'Bật đèn'),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                flex: 4,
                child: FilledButton.icon(
                  onPressed: scanning ? null : notifier.resumeScanning,
                  icon: const Icon(
                    Icons.center_focus_strong_outlined,
                    size: 18,
                  ),
                  label: Text(
                    scanning ? 'Đang phân tích…' : 'Chụp & phân tích',
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),
          const Text(
            'Đặt thiết bị trong khung, giữ máy ổn định và đủ ánh sáng.',
            style: TextStyle(fontSize: 12, color: FlColors.muted),
          ),
        ],
      ),
    );

    final resultCard = _ResultPanel(
      uiState: uiState,
      onConfirm: () => _confirmResult(uiState),
      onCopy: _copyCode,
    );

    final helpCard = FlCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            title: 'Bạn không thấy kết quả đúng?',
            subtitle: 'Chụp lại ở góc khác hoặc nhập thông tin thủ công nếu độ tin cậy thấp.',
          ),
          const Gap(18),
          OutlinedButton(
            onPressed: _enterCodeManually,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Chọn loại thiết bị khác'),
            ),
          ),
          const Gap(14),
          const InfoBanner(
            icon: Icons.cloud_off_outlined,
            tone: FlTone.info,
            title: 'Không gửi ảnh lên đám mây',
            subtitle: 'AI hoạt động khi mất kết nối.',
          ),
        ],
      ),
    );

    return DesktopPage(
      heading: DesktopPageHeading(
        title: 'Quét mã & nhận diện AI',
        subtitle: 'Nhận diện thiết bị tại hiện trường và xác nhận trước khi ghi vào phiếu.',
        action: FilledButton.icon(
          onPressed: _enterCodeManually,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nhập mã thủ công'),
        ),
      ),
      children: [
        FlSplitRow(
          main: cameraCard,
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [resultCard, const Gap(16), helpCard],
          ),
          flex: 6,
          equalHeight: false,
        ),
      ],
    );
  }

  Widget _buildMobile(ScannerUiState uiState, Widget camera) {
    final hasResult =
        uiState.latestResult != null && uiState.status == ScannerStatus.success;
    final guess = _AiGuess.parse(uiState.detectedObjects);

    return MobilePage(
      title: 'Quét & nhận diện AI',
      showBack: true,
      trailing: IconButton(
        tooltip: 'Nhập mã thủ công',
        icon: const Icon(Icons.keyboard_alt_outlined, color: FlColors.muted),
        onPressed: _enterCodeManually,
      ),
      belowTitle: const Row(
        children: [
          StatusPill(label: 'AI On-Device', bold: true),
          Gap(10),
          Flexible(
            child: Text(
              'Xử lý ngay trên thiết bị',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: FlColors.muted),
            ),
          ),
        ],
      ),
      bottomAction: MobilePrimaryButton(
        label: 'Dùng tài sản này',
        onPressed: hasResult || guess != null
            ? () => _confirmResult(uiState)
            : null,
      ),
      children: [
        SizedBox(height: 318, child: camera),
        const Gap(18),
        _MobileResultCard(uiState: uiState, guess: guess),
      ],
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showFlSnack(context, 'Đã sao chép mã vào bộ nhớ đệm!');
  }
}

/// Hộp thoại nhập mã tài sản.
///
/// Tự giữ [TextEditingController] để controller chỉ bị huỷ khi hộp thoại đã
/// rời cây widget, không phải ngay lúc `pop` (khi hiệu ứng đóng còn chạy).
class _ManualCodeDialog extends StatefulWidget {
  const _ManualCodeDialog();

  @override
  State<_ManualCodeDialog> createState() => _ManualCodeDialogState();
}

class _ManualCodeDialogState extends State<_ManualCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FlColors.surface,
      title: const Text(
        'Nhập mã thủ công',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(hintText: 'Ví dụ: TS-DC-0142'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Lập phiếu'),
        ),
      ],
    );
  }
}

/// Chuyển giữa chế độ nhận diện AI và quét mã.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.aiMode, required this.onChanged});

  final bool aiMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(bool value, IconData icon, String label) {
      final active = aiMode == value;
      return Expanded(
        child: Material(
          color: active ? FlColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onChanged(value),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: active
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (active) ...[
                    const Gap(16),
                    Icon(icon, size: 18, color: Colors.white),
                    const Gap(10),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: active ? Colors.white : FlColors.muted,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: FlColors.background,
        borderRadius: BorderRadius.circular(FlRadius.control),
      ),
      child: Row(
        children: [
          segment(true, Icons.center_focus_strong_outlined, 'Nhận diện AI'),
          segment(false, Icons.qr_code_2_rounded, 'Quét QR / mã vạch'),
        ],
      ),
    );
  }
}

/// Khung camera tối: preview, khung quét, nhãn AI và các trạng thái quyền.
class _CameraBox extends ConsumerWidget {
  const _CameraBox({
    required this.uiState,
    required this.controller,
    required this.aiMode,
    required this.showControls,
    required this.onManualEntry,
  });

  final ScannerUiState uiState;
  final MobileScannerController controller;
  final bool aiMode;
  final bool showControls;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(scannerControllerProvider.notifier);
    final guess = _AiGuess.parse(uiState.detectedObjects);

    return ClipRRect(
      borderRadius: BorderRadius.circular(FlRadius.card),
      child: ColoredBox(
        color: FlColors.camera,
        child: switch (uiState.status) {
          ScannerStatus.permissionDenied => _CameraMessage(
            icon: Icons.no_photography_outlined,
            title: 'Cần quyền truy cập Camera',
            message: uiState.errorMessage ?? 'Vui lòng cấp quyền camera để tiến hành quét mã kiểm kê hiện trường.',
            actionLabel: 'Cấp quyền Camera',
            onAction: notifier.requestPermission,
          ),
          ScannerStatus.permissionPermanentlyDenied => _CameraMessage(
            icon: Icons.settings_suggest_outlined,
            title: 'Quyền Camera đã bị tắt',
            message: uiState.errorMessage ?? 'Quyền camera bị từ chối vĩnh viễn. Vui lòng mở Cài đặt thiết bị để kích hoạt lại.',
            actionLabel: 'Mở Cài đặt hệ thống',
            onAction: notifier.openSettings,
          ),
          ScannerStatus.error => _CameraMessage(
            icon: Icons.error_outline,
            title: 'Không thể khởi động camera',
            message: uiState.errorMessage ?? 'Đã xảy ra lỗi kết nối phần cứng.',
            actionLabel: 'Thử lại',
            onAction: notifier.initialize,
          ),
          _ => Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: controller,
                fit: BoxFit.cover,
                // ScannerController đã tự dừng/mở camera theo vòng đời app;
                // để widget làm thêm lần nữa sẽ gọi start() hai lần sau hộp
                // thoại xin quyền và báo "The scanner was already started".
                useAppLifecycleState: false,
                placeholderBuilder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: FlColors.cameraHighlight,
                  ),
                ),
                errorBuilder: (context, error) => _CameraMessage(
                  icon: Icons.error_outline,
                  title: 'Không mở được camera',
                  message: _cameraErrorText(error),
                  actionLabel: 'Thử lại',
                  onAction: notifier.resumeScanning,
                  secondaryLabel: 'Nhập mã thủ công',
                  onSecondary: onManualEntry,
                ),
                onDetect: notifier.onBarcodeScanned,
              ),
              const Positioned(
                left: 18,
                top: 16,
                child: Text(
                  'CAM 01  •  KHUNG HÌNH TRỰC TIẾP',
                  style: TextStyle(color: Color(0xFF8EACB4), fontSize: 10),
                ),
              ),
              if (showControls)
                Positioned(
                  right: 8,
                  top: 6,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Bật/Tắt đèn',
                        onPressed: notifier.toggleTorch,
                        icon: Icon(
                          uiState.isTorchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đổi camera',
                        onPressed: notifier.switchCamera,
                        icon: const Icon(
                          Icons.cameraswitch_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              // Ẩn khung quét và nhãn khi camera lỗi để thông báo lỗi dễ đọc.
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, camera, _) => camera.error != null
                    ? const SizedBox.shrink()
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          const ScannerOverlayWidget(boxSize: 240),
                          // Nhãn nhận diện ở giữa khung
                          Align(
                            alignment: const Alignment(0, 0.55),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: FlColors.cameraHighlight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                guess != null && aiMode
                                    ? '${guess.label}${guess.confidence != null ? ' • ${guess.percent}' : ''}'
                                    : (aiMode ? 'QR · AI' : 'QR / mã vạch'),
                                style: const TextStyle(
                                  color: Color(0xFF103E39),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 16,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    aiMode ? 'Đưa mã hoặc thiết bị vào khung' : 'Căn chỉnh mã QR / mã vạch trong khung',
                                    style: const TextStyle(
                                      color: Color(0xFFD5E6E6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: FlColors.cameraHighlight,
                                ),
                                const Gap(6),
                                const Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Color(0xFFB7DECF),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              if (uiState.status == ScannerStatus.success &&
                  uiState.latestResult != null)
                _ScanSuccessOverlay(
                  frame: uiState.successFrame,
                  code: uiState.latestResult!.displayValue,
                ),
              if (uiState.status == ScannerStatus.loadingModel ||
                  uiState.status == ScannerStatus.requestingPermission)
                Container(
                  color: FlColors.camera.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: FlColors.cameraHighlight,
                        ),
                        const Gap(16),
                        Text(
                          uiState.status == ScannerStatus.loadingModel
                              ? 'Đang nạp mô hình Edge AI...'
                              : 'Đang kiểm tra quyền truy cập Camera...',
                          style: const TextStyle(color: Color(0xFFD5E6E6)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}

/// Hình xác nhận quét thành công: khung hình vừa quét làm nền mờ, dấu tích lớn
/// và mã đã đọc, thay cho khung xanh trống sau khi camera dừng.
class _ScanSuccessOverlay extends StatelessWidget {
  const _ScanSuccessOverlay({required this.frame, required this.code});

  final Uint8List? frame;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (frame != null)
          Image.memory(frame!, fit: BoxFit.cover, gaplessPlayback: true),
        ColoredBox(
          color: FlColors.camera.withValues(alpha: frame != null ? 0.72 : 1),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: FlColors.cameraHighlight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FlColors.cameraHighlight.withValues(alpha: 0.45),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: Color(0xFF103E39),
                ),
              ),
              const Gap(16),
              const Text(
                'Đã quét thành công',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Color(0xFFD5E6E6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: FlColors.cameraHighlight),
            const Gap(14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD5E6E6), fontSize: 13),
            ),
            if (actionLabel != null) ...[
              const Gap(20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (secondaryLabel != null) ...[
              const Gap(4),
              TextButton(
                onPressed: onSecondary,
                style: TextButton.styleFrom(
                  foregroundColor: FlColors.cameraHighlight,
                ),
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thẻ "Kết quả nhận diện" trên desktop.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.uiState,
    required this.onConfirm,
    required this.onCopy,
  });

  final ScannerUiState uiState;
  final VoidCallback onConfirm;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final result = uiState.status == ScannerStatus.success
        ? uiState.latestResult
        : null;
    final guess = _AiGuess.parse(uiState.detectedObjects);
    final hasAny = result != null || guess != null;
    final confidence = guess?.confidence;

    return FlCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            title: 'Kết quả nhận diện',
            subtitle: 'Kết quả gợi ý cần được kiểm kê viên xác nhận',
          ),
          const Gap(14),
          if (!hasAny) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(label: 'Đang chờ', tone: FlTone.neutral),
            ),
            const Gap(12),
            const Text(
              'Chưa phát hiện thiết bị',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const Gap(8),
            const Text(
              'Đưa mã QR, mã vạch hoặc thiết bị vào khung camera.',
              style: TextStyle(fontSize: 13, color: FlColors.muted),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                label: confidence == null
                    ? 'Đã đọc mã'
                    : confidence >= 0.8
                    ? 'Độ tin cậy cao'
                    : 'Độ tin cậy thấp',
                tone: confidence == null || confidence >= 0.8
                    ? FlTone.success
                    : FlTone.warning,
              ),
            ),
            const Gap(12),
            Text(
              guess?.label ?? 'Mã ${_typeLabel(result!.type)}',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
            ),
            const Gap(8),
            Text(
              result != null
                  ? 'Đọc từ mã ${_typeLabel(result.type)}'
                  : 'Nhận diện bằng Edge AI',
              style: const TextStyle(fontSize: 13, color: FlColors.muted),
            ),
            if (confidence != null) ...[
              const Gap(20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Độ tin cậy',
                      style: TextStyle(fontSize: 13, color: FlColors.muted),
                    ),
                  ),
                  Text(
                    guess!.percent,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FlColors.primary,
                    ),
                  ),
                ],
              ),
              const Gap(10),
              FlProgressBar(value: confidence),
            ],
            const Gap(18),
            const Divider(),
            KeyValueRow(
              label: 'Mã đề xuất',
              divider: false,
              value: Row(
                children: [
                  Expanded(
                    child: Text(
                      result?.displayValue ?? 'Chưa đọc được mã',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (result != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Sao chép',
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      onPressed: () => onCopy(result.rawValue),
                    ),
                ],
              ),
            ),
          ],
          const Gap(16),
          FilledButton.icon(
            onPressed: hasAny ? onConfirm : null,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Xác nhận & lập phiếu'),
          ),
        ],
      ),
    );
  }
}

/// Thẻ kết quả nhận diện trên mobile (M02).
class _MobileResultCard extends StatelessWidget {
  const _MobileResultCard({required this.uiState, required this.guess});

  final ScannerUiState uiState;
  final _AiGuess? guess;

  @override
  Widget build(BuildContext context) {
    final result = uiState.status == ScannerStatus.success
        ? uiState.latestResult
        : null;
    final confidence = guess?.confidence;
    final title =
        guess?.label ??
        (result != null
            ? 'Mã ${_typeLabel(result.type)}'
            : 'Chưa phát hiện thiết bị');

    return FlCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('Kết quả nhận diện')),
              if (confidence != null)
                StatusPill(
                  label: '${(confidence * 100).round()}% tin cậy',
                  bold: true,
                ),
            ],
          ),
          const Gap(12),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const Gap(6),
          Text(
            result != null
                ? 'Mã ${result.displayValue}'
                : 'Đưa mã hoặc thiết bị vào khung camera',
            style: const TextStyle(fontSize: 13, color: FlColors.muted),
          ),
          const Gap(14),
          const Divider(),
          const Gap(14),
          Text(
            result != null || guess != null
                ? 'Sẵn sàng ghi vào phiếu kiểm kê'
                : 'Đang chờ kết quả',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: FlColors.primary,
            ),
          ),
          const Gap(6),
          const Text(
            'AI chạy ngoại tuyến, không tải ảnh lên máy chủ.',
            style: TextStyle(fontSize: 12, color: FlColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Thông báo lỗi camera dễ hiểu bằng tiếng Việt thay cho thông điệp của plugin.
String _cameraErrorText(MobileScannerException error) {
  final details = error.errorDetails?.message ?? '';
  if (details.toLowerCase().contains('no camera')) {
    return 'Thiết bị này không có camera. Bạn có thể nhập mã thủ công.';
  }
  return switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied =>
      'Ứng dụng chưa được cấp quyền camera. Hãy bật trong Cài đặt.',
    MobileScannerErrorCode.unsupported =>
      'Thiết bị không hỗ trợ quét bằng camera. Bạn có thể nhập mã thủ công.',
    MobileScannerErrorCode.controllerAlreadyInitialized ||
    MobileScannerErrorCode.controllerInitializing =>
      'Camera đang được khởi động. Vui lòng thử lại.',
    _ =>
      details.isNotEmpty
          ? 'Camera gặp lỗi: $details'
          : 'Camera gặp lỗi không xác định. Vui lòng thử lại.',
  };
}

String _typeLabel(ScanCodeType type) => switch (type) {
  ScanCodeType.qrCode => 'QR',
  ScanCodeType.barCode => 'vạch',
  ScanCodeType.unknown => 'thiết bị',
};
