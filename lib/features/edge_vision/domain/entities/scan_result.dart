enum ScanCodeType {
  qrCode,
  barCode,
  unknown,
}

class ScanResult {
  final String rawValue;
  final String displayValue;
  final ScanCodeType type;
  final DateTime scannedAt;

  const ScanResult({
    required this.rawValue,
    required this.displayValue,
    this.type = ScanCodeType.unknown,
    required this.scannedAt,
  });

  @override
  String toString() =>
      'ScanResult(rawValue: $rawValue, displayValue: $displayValue, type: $type, scannedAt: $scannedAt)';
}
