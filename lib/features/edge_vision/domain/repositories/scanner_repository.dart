import 'package:mobile_scanner/mobile_scanner.dart';

abstract class ScannerRepository {
  /// Instance của MobileScannerController phục vụ quản lý camera
  MobileScannerController get controller;

  /// Kiểm tra trạng thái cấp quyền camera
  Future<bool> checkPermission();

  /// Yêu cầu cấp quyền truy cập camera
  Future<bool> requestPermission();

  /// Bật/tắt đèn Flash
  Future<void> toggleTorch();

  /// Chuyển đổi camera trước/sau
  Future<void> switchCamera();

  /// Bắt đầu quét
  Future<void> start();

  /// Tạm dừng/Dừng quét
  Future<void> stop();

  /// Giải phóng tài nguyên controller
  void dispose();
}
