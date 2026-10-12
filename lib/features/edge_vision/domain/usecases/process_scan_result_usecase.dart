import 'package:mobile_scanner/mobile_scanner.dart';
import '../entities/scan_result.dart';

class ProcessScanResultUseCase {
  const ProcessScanResultUseCase();

  ScanResult? execute(Barcode barcode) {
    final raw = barcode.rawValue ?? barcode.displayValue;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final trimmed = raw.trim();
    final ScanCodeType barcodeType = _mapBarcodeFormat(barcode.format);

    return ScanResult(
      rawValue: trimmed,
      displayValue: barcode.displayValue?.trim() ?? trimmed,
      type: barcodeType,
      scannedAt: DateTime.now(),
    );
  }

  ScanResult? executeFromRaw(
    String rawData, {
    ScanCodeType type = ScanCodeType.unknown,
  }) {
    if (rawData.trim().isEmpty) {
      return null;
    }
    final trimmed = rawData.trim();
    return ScanResult(
      rawValue: trimmed,
      displayValue: trimmed,
      type: type,
      scannedAt: DateTime.now(),
    );
  }

  ScanCodeType _mapBarcodeFormat(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return ScanCodeType.qrCode;
      case BarcodeFormat.code128:
      case BarcodeFormat.code39:
      case BarcodeFormat.code93:
      case BarcodeFormat.ean13:
      case BarcodeFormat.ean8:
      case BarcodeFormat.upcA:
      case BarcodeFormat.upcE:
      case BarcodeFormat.dataMatrix:
      case BarcodeFormat.pdf417:
        return ScanCodeType.barCode;
      default:
        return ScanCodeType.unknown;
    }
  }
}
