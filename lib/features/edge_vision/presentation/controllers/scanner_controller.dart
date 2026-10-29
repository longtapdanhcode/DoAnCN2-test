import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/scanner_repository_impl.dart';
import '../../data/repositories/tflite_vision_repository_impl.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/entities/vision_analysis.dart';
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

/// Số liệu chẩn đoán Edge AI hiển thị ở màn Quét, để biết AI có chạy và
/// vì sao chưa ra kết quả.
class AiDiagnostics {
  const AiDiagnostics({
    this.modelStatus = VisionModelStatus.notLoaded,
    this.modelError,
    this.labelCount = 0,
    this.framesReceived = 0,
    this.framesWithoutImage = 0,
    this.framesSkipped = 0,
    this.framesAnalyzed = 0,
    this.last,
  });

  final VisionModelStatus modelStatus;
  final String? modelError;
  final int labelCount;

  /// Khung camera gửi sang (có hoặc không có mã).
  final int framesReceived;

  /// Khung không kèm ảnh (AI không có gì để phân tích).
  final int framesWithoutImage;

  /// Khung bị bỏ vì AI còn bận khung trước.
  final int framesSkipped;

  final int framesAnalyzed;

  /// Kết quả khung vừa phân tích.
  final VisionAnalysis? last;

  AiDiagnostics copyWith({
    VisionModelStatus? modelStatus,
    String? modelError,
    int? labelCount,
    int? framesReceived,
    int? framesWithoutImage,
    int? framesSkipped,
    int? framesAnalyzed,
    VisionAnalysis? last,
  }) => AiDiagnostics(
    modelStatus: modelStatus ?? this.modelStatus,
    modelError: modelError ?? this.modelError,
    labelCount: labelCount ?? this.labelCount,
    framesReceived: framesReceived ?? this.framesReceived,
    framesWithoutImage: framesWithoutImage ?? this.framesWithoutImage,
    framesSkipped: framesSkipped ?? this.framesSkipped,
    framesAnalyzed: framesAnalyzed ?? this.framesAnalyzed,
    last: last ?? this.last,
  );
}

class ScannerUiState {
  final ScannerStatus status;
  final bool isTorchOn;
  final ScanResult? latestResult;
  final List<String> detectedObjects;

  /// Khung hình camera lúc quét thành công, dùng làm hình xác nhận.
  final Uint8List? successFrame;
  final String? errorMessage;

  /// Chẩn đoán Edge AI (mô hình, số khung, kết quả cao nhất).
  final AiDiagnostics ai;

  const ScannerUiState({
    this.ai = const AiDiagnostics(),
    this.status = ScannerStatus.initial,
    this.isTorchOn = false,
    this.latestResult,
    this.detectedObjects = const [],
    this.successFrame,
    this.errorMessage,
  });

  ScannerUiState copyWith({
    ScannerStatus? status,
    bool? isTorchOn,
    ScanResult? latestResult,
    List<String>? detectedObjects,
    Uint8List? successFrame,
    bool clearSuccessFrame = false,
    String? errorMessage,
    AiDiagnostics? ai,
  }) {
    return ScannerUiState(
      ai: ai ?? this.ai,
      status: status ?? this.status,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      latestResult: latestResult ?? this.latestResult,
      detectedObjects: detectedObjects ?? this.detectedObjects,
      successFrame: clearSuccessFrame
          ? null
          : (successFrame ?? this.successFrame),
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

  /// Số khung liên tiếp không nhận ra gì; đủ [_clearAfterEmptyFrames] thì xoá nhãn cũ.
  int _emptyFrames = 0;
  static const int _clearAfterEmptyFrames = 3;

  @override
  ScannerUiState build() {
    return const ScannerUiState();
  }

  /// Chuỗi tuần tự cho mọi lệnh bật/tắt camera.
  ///
  /// Sự kiện vòng đời (inactive → resumed) đến ngay sau hộp thoại xin quyền,
  /// nên lệnh start có thể chạy khi lệnh stop trước đó chưa xong và iOS báo
  /// "The scanner was already started". Xếp hàng các lệnh để tránh chồng nhau.
  Future<void> _cameraQueue = Future<void>.value();

  Future<void> _enqueueCamera(Future<void> Function() operation) {
    final next = _cameraQueue.then((_) => operation());
    _cameraQueue = next.catchError((Object _) {});
    return next;
  }

  ScannerRepository get _repository => ref.read(scannerRepositoryProvider);
  VisionAiRepository get _visionAiRepo => ref.read(visionAiRepositoryProvider);
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
    state = state.copyWith(
      ai: state.ai.copyWith(
        modelStatus: _visionAiRepo.modelStatus,
        modelError: _visionAiRepo.modelError,
        labelCount: _visionAiRepo.labelCount,
      ),
    );

    // 2. Kiểm tra và xin cấp quyền Camera
    final status = await Permission.camera.status;
    if (status.isGranted) {
      await startCamera();
    } else if (status.isPermanentlyDenied) {
      state = state.copyWith(
        status: ScannerStatus.permissionPermanentlyDenied,
        errorMessage: 'Quyền truy cập Camera đã bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.',
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
        errorMessage: 'Quyền Camera bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt thiết bị.',
      );
    } else {
      state = state.copyWith(
        status: ScannerStatus.permissionDenied,
        errorMessage: 'Ứng dụng cần quyền Camera để quét mã tài sản & kiểm kê hiện trường.',
      );
    }
  }

  /// Mở màn hình cài đặt của ứng dụng
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  /// Bắt đầu stream camera
  Future<void> startCamera() => _enqueueCamera(() async {
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
  });

  /// Tạm dừng stream camera
  Future<void> stopCamera() => _enqueueCamera(() async {
    try {
      await _repository.stop();
      if (state.status == ScannerStatus.scanning) {
        state = state.copyWith(status: ScannerStatus.paused);
      }
    } catch (e) {
      debugPrint('[ScannerController] Lỗi khi stop camera: $e');
    }
  });

  /// Xử lý khi ứng dụng chuyển sang nền
  Future<void> onAppInactive() async {
    if (state.status == ScannerStatus.scanning) {
      _wasScanningBeforeInactive = true;
      await _enqueueCamera(() async {
        try {
          await _repository.stop();
          state = state.copyWith(status: ScannerStatus.paused);
          debugPrint('[ScannerController] App inactive: Camera đã dừng.');
        } catch (e) {
          debugPrint('[ScannerController] Lỗi dừng camera khi inactive: $e');
        }
      });
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
    final imageBytes = capture.image;
    if (imageBytes == null || imageBytes.isEmpty) {
      state = state.copyWith(
        ai: state.ai.copyWith(
          framesReceived: state.ai.framesReceived + 1,
          framesWithoutImage: state.ai.framesWithoutImage + 1,
        ),
      );
      return;
    }
    // Cơ chế bảo vệ CPU: Bỏ qua frame (drop frame) nếu AI đang bận inference
    if (_isAnalyzing) {
      state = state.copyWith(
        ai: state.ai.copyWith(
          framesReceived: state.ai.framesReceived + 1,
          framesSkipped: state.ai.framesSkipped + 1,
        ),
      );
      return;
    }
    state = state.copyWith(
      ai: state.ai.copyWith(framesReceived: state.ai.framesReceived + 1),
    );
    _isAnalyzing = true;
    try {
      final analysis = await _visionAiRepo.analyze(imageBytes);
      final objects = analysis.labels;
      final ai = state.ai.copyWith(
        framesAnalyzed: state.ai.framesAnalyzed + 1,
        last: analysis,
      );
      if (objects.isNotEmpty) {
        _emptyFrames = 0;
        state = state.copyWith(detectedObjects: objects, ai: ai);
      } else if (state.detectedObjects.isNotEmpty &&
          ++_emptyFrames >= _clearAfterEmptyFrames) {
        _emptyFrames = 0;
        state = state.copyWith(detectedObjects: const [], ai: ai);
      } else {
        state = state.copyWith(ai: ai);
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
        unawaited(_enqueueCamera(_repository.stop));
        state = state.copyWith(
          status: ScannerStatus.success,
          latestResult: result,
          successFrame: capture.image,
        );
        break;
      }
    }
  }

  /// Tiếp tục quét mã tiếp theo
  Future<void> resumeScanning() async {
    state = state.copyWith(
      latestResult: null,
      clearSuccessFrame: true,
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
