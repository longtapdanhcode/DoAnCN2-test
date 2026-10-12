import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/repositories/scanner_repository.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  ScannerRepositoryImpl({MobileScannerController? controller})
      : _controller = controller ??
            MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              autoStart: false,
              returnImage: true,
            );

  final MobileScannerController _controller;

  @override
  MobileScannerController get controller => _controller;

  @override
  Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<void> toggleTorch() async {
    await _controller.toggleTorch();
  }

  @override
  Future<void> switchCamera() async {
    await _controller.switchCamera();
  }

  @override
  Future<void> start() async {
    await _controller.start();
  }

  @override
  Future<void> stop() async {
    try {
      await _controller.stop();
    } catch (_) {
      // Bỏ qua nếu camera đã ở trạng thái dừng
    }
  }

  @override
  void dispose() {
    _controller.dispose();
  }
}
