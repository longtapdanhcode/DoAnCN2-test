import 'package:flutter/foundation.dart';

import '../domain/damage_calculator.dart';
import '../domain/damage_measurer.dart';
import '../domain/entities/damage_enums.dart';
import '../domain/entities/surface_assessment.dart';
import 'damage_format.dart';

/// Một dòng hư hỏng đang sửa trên phiếu.
class DamageRowDraft {
  DamageRowDraft({
    required this.type,
    required this.quantityText,
    this.source = MeasurementSource.manual,
    this.confidence,
  }) : _aiText = source == MeasurementSource.ai ? quantityText : null;

  DamageType type;
  String quantityText;
  MeasurementSource source;
  final double? confidence;

  /// Số AI đo ban đầu, để biết người kiểm kê đã sửa hay chưa.
  final String? _aiText;

  double? get quantity => parseDecimal(quantityText);

  DamageMeasurement? toMeasurement() {
    final q = quantity;
    if (q == null || q <= 0) return null;
    final edited = _aiText != null && quantityText.trim() != _aiText.trim();
    return DamageMeasurement(
      type: type,
      quantity: q,
      source: edited ? MeasurementSource.edited : source,
      confidence: confidence,
    );
  }
}

/// Trạng thái phần "Đánh giá hư hỏng bề mặt" trên phiếu kiểm kê.
class SurfaceAssessmentDraft extends ChangeNotifier {
  SurfaceAssessmentDraft();

  SurfaceMaterial material = SurfaceMaterial.paintedWall;
  String surfaceAreaText = '';
  final List<DamageRowDraft> rows = [];

  /// Diện tích vùng AI nhìn thấy lúc quét (gợi ý, không tự điền).
  double? capturedAreaM2;

  /// Có đo bằng thẻ QR không (để ghi chú trên phiếu).
  bool measuredWithMarker = false;

  /// Điền từ kết quả đo ở màn Quét.
  void loadMeasurement(FrameMeasurement m) {
    rows
      ..clear()
      ..addAll([
        for (final d in m.measurements)
          DamageRowDraft(
            type: d.type,
            quantityText: d.quantity > 0 ? formatDecimal(d.quantity) : '',
            source: d.quantity > 0
                ? MeasurementSource.ai
                : MeasurementSource.manual,
            confidence: d.confidence,
          ),
      ]);
    capturedAreaM2 = m.capturedAreaM2;
    measuredWithMarker = m.hasScale;
    notifyListeners();
  }

  /// Mở lại đánh giá đã lưu (bản nháp).
  void loadAssessment(SurfaceAssessment a) {
    material = a.material;
    surfaceAreaText = formatDecimal(a.surfaceAreaM2);
    rows
      ..clear()
      ..addAll([
        for (final m in a.measurements)
          DamageRowDraft(
            type: m.type,
            quantityText: formatDecimal(m.quantity),
            // Số đã lưu coi như số người kiểm kê đã xác nhận.
            source: m.source,
            confidence: m.confidence,
          ),
      ]);
    notifyListeners();
  }

  /// Điền diện tích bề mặt khi còn trống (ví dụ lấy từ danh mục).
  void suggestSurfaceArea(double? m2) {
    if (m2 == null || m2 <= 0 || surfaceAreaText.trim().isNotEmpty) return;
    surfaceAreaText = formatDecimal(m2);
    notifyListeners();
  }

  void setMaterial(SurfaceMaterial value) {
    material = value;
    notifyListeners();
  }

  void setSurfaceArea(String text) {
    surfaceAreaText = text;
    notifyListeners();
  }

  void addRow(DamageType type) {
    rows.add(DamageRowDraft(type: type, quantityText: ''));
    notifyListeners();
  }

  void removeRow(DamageRowDraft row) {
    rows.remove(row);
    notifyListeners();
  }

  void updateRow(DamageRowDraft row, {DamageType? type, String? quantity}) {
    if (type != null) row.type = type;
    if (quantity != null) row.quantityText = quantity;
    notifyListeners();
  }

  double? get surfaceAreaM2 => parseDecimal(surfaceAreaText);

  List<DamageMeasurement> get measurements => [
    for (final r in rows) ?r.toMeasurement(),
  ];

  /// Có nhập gì vào phần đánh giá không (không thì phiếu lưu như cũ).
  bool get isUsed => rows.isNotEmpty || surfaceAreaText.trim().isNotEmpty;

  /// Lỗi cần sửa trước khi lưu, hoặc `null`.
  String? validate() {
    if (!isUsed) return null;
    final area = surfaceAreaM2;
    if (area == null || area <= 0) {
      return 'Nhập diện tích bề mặt (m²) để tính chỉ số hư hại';
    }
    for (final r in rows) {
      final q = r.quantity;
      if (q == null || q <= 0) {
        return 'Nhập số đo cho "${r.type.label}" hoặc xoá dòng này';
      }
    }
    return null;
  }

  /// Kết quả tính với [calculator]; `null` khi chưa dùng hoặc còn lỗi.
  SurfaceAssessment? assess(DamageCalculator calculator) {
    if (!isUsed || validate() != null) return null;
    return calculator.assess(
      material: material,
      surfaceAreaM2: surfaceAreaM2!,
      measurements: measurements,
    );
  }
}
