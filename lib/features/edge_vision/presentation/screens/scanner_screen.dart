import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/scanner_controller.dart';
import '../widgets/scanner_overlay.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  bool _isNavigating = false;
  DateTime? _lastNavigationTime;

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

    context.push(
      '/audit-form',
      extra: {
        'scanCode': scanCode,
        'aiLabel': aiLabel,
      },
    ).then((_) {
      _isNavigating = false;
      if (mounted) {
        ref.read(scannerControllerProvider.notifier).resumeScanning();
      }
    });
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
    final controllerNotifier = ref.read(scannerControllerProvider.notifier);
    final scannerRepo = ref.watch(scannerRepositoryProvider);

    // Tự động điều hướng sang Form kiểm kê khi quét mã thành công
    ref.listen<ScannerUiState>(scannerControllerProvider, (previous, next) {
      if (previous?.status != ScannerStatus.success &&
          next.status == ScannerStatus.success &&
          next.latestResult != null) {
        final result = next.latestResult!;
        final code = result.rawValue.isNotEmpty
            ? result.rawValue
            : result.displayValue;
        final label = next.detectedObjects.isNotEmpty
            ? next.detectedObjects.first
            : null;
        _navigateToAuditForm(code, label);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        foregroundColor: Colors.white,
        title: const Text(
          'Quét mã kiểm kê',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              uiState.isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: uiState.isTorchOn ? Colors.amber : Colors.white,
            ),
            tooltip: 'Bật/Tắt Flash',
            onPressed: () => controllerNotifier.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            tooltip: 'Đổi Camera',
            onPressed: () => controllerNotifier.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview or permission fallback
          _buildCameraView(context, uiState, scannerRepo.controller),

          // Result Sheet overlay when scan is successful
          if (uiState.status == ScannerStatus.success &&
              uiState.latestResult != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildResultCard(context, uiState, controllerNotifier),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView(
    BuildContext context,
    ScannerUiState uiState,
    MobileScannerController cameraController,
  ) {
    switch (uiState.status) {
      case ScannerStatus.permissionDenied:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  size: 64,
                  color: Colors.white70,
                ),
                const Gap(16),
                const Text(
                  'Cần quyền truy cập Camera',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Text(
                  uiState.errorMessage ??
                      'Vui lòng cấp quyền camera để tiến hành quét mã kiểm kê hiện trường.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Gap(24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(scannerControllerProvider.notifier)
                        .requestPermission();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cấp quyền Camera'),
                ),
              ],
            ),
          ),
        );

      case ScannerStatus.permissionPermanentlyDenied:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.settings_suggest_outlined,
                  size: 64,
                  color: Colors.orangeAccent,
                ),
                const Gap(16),
                const Text(
                  'Quyền Camera đã bị tắt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Text(
                  uiState.errorMessage ??
                      'Quyền camera bị từ chối vĩnh viễn. Vui lòng mở Cài đặt thiết bị để kích hoạt lại.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Gap(24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(scannerControllerProvider.notifier)
                        .openSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Mở Cài đặt hệ thống'),
                ),
              ],
            ),
          ),
        );

      case ScannerStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const Gap(16),
                const Text(
                  'Không thể khởi động camera',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Text(
                  uiState.errorMessage ?? 'Đã xảy ra lỗi kết nối phần cứng.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Gap(24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(scannerControllerProvider.notifier)
                        .initialize();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );

      case ScannerStatus.initial:
      case ScannerStatus.loadingModel:
      case ScannerStatus.requestingPermission:
      case ScannerStatus.scanning:
      case ScannerStatus.paused:
      case ScannerStatus.success:
        return Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              fit: BoxFit.cover,
              placeholderBuilder: (context) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const Gap(12),
                      Text(
                        'Lỗi camera: ${error.errorCode.message}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      if (error.errorDetails?.message != null) ...[
                        const Gap(6),
                        Text(
                          error.errorDetails!.message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              onDetect: (capture) {
                ref
                    .read(scannerControllerProvider.notifier)
                    .onBarcodeScanned(capture);
              },
            ),
            const ScannerOverlayWidget(),
            const Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Căn chỉnh mã trong khung quét',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black87,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (uiState.detectedObjects.isNotEmpty)
              Positioned(
                top: 65,
                left: 16,
                right: 16,
                child: Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: uiState.detectedObjects.map((obj) {
                      return Chip(
                        avatar: const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.lightBlueAccent,
                        ),
                        label: Text(
                          obj,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.lightBlueAccent),
                      );
                    }).toList(),
                  ),
                ),
              ),
            if (uiState.status == ScannerStatus.loadingModel ||
                uiState.status == ScannerStatus.requestingPermission)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const Gap(16),
                      Text(
                        uiState.status == ScannerStatus.loadingModel
                            ? 'Đang nạp mô hình Edge AI...'
                            : 'Đang kiểm tra quyền truy cập Camera...',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
    }
  }

  Widget _buildResultCard(
    BuildContext context,
    ScannerUiState uiState,
    ScannerController notifier,
  ) {
    final result = uiState.latestResult!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
                const Gap(8),
                Text(
                  'Phát hiện mã (${result.type.name.toUpperCase()})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Sao chép',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.rawValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã vào bộ nhớ đệm!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                result.displayValue,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final code = result.rawValue.isNotEmpty
                          ? result.rawValue
                          : result.displayValue;
                      final label = uiState.detectedObjects.isNotEmpty
                          ? uiState.detectedObjects.first
                          : null;
                      _navigateToAuditForm(code, label);
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Nhập kiểm kê'),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => notifier.resumeScanning(),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Tiếp tục quét'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
