import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/scanner_repository_impl.dart';
import '../../data/repositories/tflite_vision_repository_impl.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../domain/repositories/vision_ai_repository.dart';
import '../../domain/usecases/process_scan_result_usecase.dart';

part 'scanner_controller.g.dart';

typedef MobileScannerCapture = BarcodeCapture;

enum ScannerStatus {
  initial,
  loadingModel,
  requestingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  scanning,
  paused,
  success,
  error,
}

class ScannerUiState {
  final ScannerStatus status;
  final bool isTorchOn;
  final ScanResult? latestResult;
  final List<String> detectedObjects;
  final String? errorMessage;

  const ScannerUiState({
    this.status = ScannerStatus.initial,
    this.isTorchOn = false,
    this.latestResult,
    this.detectedObjects = const [],
    this.errorMessage,
  });

  ScannerUiState copyWith({
    ScannerStatus? status,
    bool? isTorchOn,
    ScanResult? latestResult,
    List<String>? detectedObjects,
    String? errorMessage,
  }) {
    return ScannerUiState(
      status: status ?? this.status,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      latestResult: latestResult ?? this.latestResult,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      errorMessage: errorMessage,
    );
  }
}

@riverpod
ScannerRepository scannerRepository(Ref ref) {
  final repo = ScannerRepositoryImpl();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
}

@riverpod
ProcessScanResultUseCase processScanResultUseCase(Ref ref) {
  return const ProcessScanResultUseCase();
}

@riverpod
class ScannerController extends _$ScannerController {
  bool _wasScanningBeforeInactive = false;
  bool _isAnalyzing = false;

  @override
  ScannerUiState build() {
    return const ScannerUiState();
  }

  ScannerRepository get _repository => ref.read(scannerRepositoryProvider);
  VisionAiRepository get _visionAiRepo =>
      ref.read(visionAiRepositoryProvider);
  ProcessScanResultUseCase get _processUseCase =>
      ref.read(processScanResultUseCaseProvider);

  /// Khởi tạo model AI và kiểm tra quyền truy cập camera trước khi mở camera stream
  Future<void> initialize() async {
    state = state.copyWith(status: ScannerStatus.loadingModel);

    // 1. Tải mô hình AI on-device
    try {
      await _visionAiRepo.loadModel();
    } catch (e) {
      debugPrint('[ScannerController] Error loading AI model: $e');
    }

    // 2. Kiểm tra và xin cấp quyền Camera
    final status = await Permission.camera.status;
    if (status.isGranted) {
      await startCamera();
    } else if (status.isPermanentlyDenied) {
      state = state.copyWith(
        status: ScannerStatus.permissionPermanentlyDenied,
        errorMessage:
            'Quyền truy cập Camera đã bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.',
      );
    } else {
      await requestPermission();
    }
  }

  /// Yêu cầu cấp quyền Camera từ hệ thống
  Future<void> requestPermission() async {
    state = state.copyWith(status: ScannerStatus.requestingPermission);

    final status = await Permission.camera.request();
    if (status.isGranted) {
      await startCamera();
    } else if (status.isPermanentlyDenied) {
      state = state.copyWith(
        status: ScannerStatus.permissionPermanentlyDenied,
        errorMessage:
            'Quyền Camera bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt thiết bị.',
      );
    } else {
      state = state.copyWith(
        status: ScannerStatus.permissionDenied,
        errorMessage:
            'Ứng dụng cần quyền Camera để quét mã tài sản & kiểm kê hiện trường.',
      );
    }
  }

  /// Mở màn hình cài đặt của ứng dụng
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  /// Bắt đầu stream camera
  Future<void> startCamera() async {
    try {
      await _repository.start();
      state = state.copyWith(
        status: ScannerStatus.scanning,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('[ScannerController] Lỗi khi start camera: $e');
      state = state.copyWith(
        status: ScannerStatus.error,
        errorMessage: 'Không thể khởi động camera: $e',
      );
    }
  }

  /// Tạm dừng stream camera
  Future<void> stopCamera() async {
    try {
      await _repository.stop();
      if (state.status == ScannerStatus.scanning) {
        state = state.copyWith(status: ScannerStatus.paused);
      }
    } catch (e) {
      debugPrint('[ScannerController] Lỗi khi stop camera: $e');
    }
  }

  /// Xử lý khi ứng dụng chuyển sang nền
  Future<void> onAppInactive() async {
    if (state.status == ScannerStatus.scanning) {
      _wasScanningBeforeInactive = true;
      try {
        await _repository.stop();
        state = state.copyWith(status: ScannerStatus.paused);
        debugPrint('[ScannerController] App inactive: Camera đã dừng.');
      } catch (e) {
        debugPrint('[ScannerController] Lỗi dừng camera khi inactive: $e');
      }
    }
  }

  /// Xử lý khi ứng dụng quay trở lại foreground
  Future<void> onAppResumed() async {
    if (state.status == ScannerStatus.permissionDenied ||
        state.status == ScannerStatus.permissionPermanentlyDenied) {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        await startCamera();
        return;
      }
    }

    if (_wasScanningBeforeInactive) {
      _wasScanningBeforeInactive = false;
      await startCamera();
      debugPrint('[ScannerController] App resumed: Camera đã khởi động lại.');
    }
  }

  /// Phân tích frame ảnh camera on-device với cơ chế bảo vệ CPU
  Future<void> processCameraFrame(MobileScannerCapture capture) async {
    // Cơ chế bảo vệ CPU: Bỏ qua frame (drop frame) nếu AI đang bận inference
    if (_isAnalyzing) return;

    final imageBytes = capture.image;
    if (imageBytes == null || imageBytes.isEmpty) return;

    _isAnalyzing = true;
    try {
      final width = capture.size.width.toInt();
      final height = capture.size.height.toInt();

      final objects = await _visionAiRepo.analyzeFrame(
        imageBytes,
        width > 0 ? width : 224,
        height > 0 ? height : 224,
      );

      if (objects.isNotEmpty) {
        state = state.copyWith(detectedObjects: objects);
      }
    } catch (e) {
      debugPrint('[ScannerController] Error during AI inference: $e');
    } finally {
      _isAnalyzing = false;
    }
  }

  /// Xử lý sự kiện khi MobileScanner phát hiện mã
  void onBarcodeScanned(BarcodeCapture capture) {
    // Kích hoạt phân tích AI trên frame ảnh camera song song
    processCameraFrame(capture);

    if (state.status != ScannerStatus.scanning) return;

    for (final barcode in capture.barcodes) {
      final result = _processUseCase.execute(barcode);
      if (result != null) {
        _repository.stop();
        state = state.copyWith(
          status: ScannerStatus.success,
          latestResult: result,
        );
        break;
      }
    }
  }

  /// Tiếp tục quét mã tiếp theo
  Future<void> resumeScanning() async {
    state = state.copyWith(
      latestResult: null,
      errorMessage: null,
    );
    await startCamera();
  }

  /// Tạm dừng quét
  Future<void> pauseScanning() async {
    await stopCamera();
  }

  /// Bật/tắt đèn Flash
  Future<void> toggleTorch() async {
    try {
      await _repository.toggleTorch();
      state = state.copyWith(isTorchOn: !state.isTorchOn);
    } catch (e) {
      // Ignored if torch not supported on device
    }
  }

  /// Đổi camera trước/sau
  Future<void> switchCamera() async {
    try {
      await _repository.switchCamera();
    } catch (e) {
      // Ignored
    }
  }
}
