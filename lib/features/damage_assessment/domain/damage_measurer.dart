import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'package:field_inventory_edge_ai/features/edge_vision/domain/entities/detection.dart';

import 'entities/damage_enums.dart';
import 'entities/surface_assessment.dart';

/// Tỉ lệ cm/pixel suy ra từ thẻ QR có cạnh thật đã biết.
@immutable
class MarkerScale {
  const MarkerScale({required this.cmPerPixel, required this.markerSidePx});

  final double cmPerPixel;

  /// Cạnh trung bình của thẻ trên ảnh (pixel).
  final double markerSidePx;

  /// Thẻ nhỏ hơn mức này trên ảnh thì sai số quá lớn, không dùng để đo.
  static const double minMarkerSidePx = 40;

  /// Từ 4 góc mã QR trên ảnh gốc. `null` khi thiếu góc hoặc thẻ quá nhỏ.
  ///
  /// Lấy trung bình 4 cạnh nên chịu được góc chụp hơi nghiêng; chỉ dùng độ
  /// dài nên không phụ thuộc chiều xoay của ảnh.
  static MarkerScale? fromCorners(List<Offset> corners, double markerCm) {
    if (corners.length != 4 || !(markerCm > 0)) return null;
    var sum = 0.0;
    for (var i = 0; i < 4; i++) {
      sum += (corners[i] - corners[(i + 1) % 4]).distance;
    }
    final side = sum / 4;
    if (!(side >= minMarkerSidePx)) return null;
    return MarkerScale(cmPerPixel: markerCm / side, markerSidePx: side);
  }
}

/// Kết quả đo một khung hình: các vùng hư hỏng đã quy ra m² / mét.
@immutable
class FrameMeasurement {
  const FrameMeasurement({
    required this.measurements,
    this.scale,
    this.capturedAreaM2,
    this.ignoredDetections = 0,
  });

  /// Không có thẻ QR đủ rõ thì [DamageMeasurement.quantity] bằng 0 (người
  /// kiểm kê tự nhập số đo).
  final List<DamageMeasurement> measurements;
  final MarkerScale? scale;

  /// Diện tích thật của vùng AI nhìn thấy (ô vuông giữa khung quét), gợi ý
  /// cho diện tích bề mặt khi danh mục chưa có.
  final double? capturedAreaM2;

  /// Số vùng phát hiện không phải hư hỏng bề mặt (bàn, ghế…).
  final int ignoredDetections;

  bool get hasScale => scale != null;
  bool get isEmpty => measurements.isEmpty;
}

/// Quy đổi khung phát hiện của AI ra khối lượng hư hỏng.
///
/// Với model phát hiện (chỉ có khung chữ nhật):
/// - Diện tích ≈ diện tích khung × [blobFill] (mặc định π/4: hình elip nội
///   tiếp khung), vì vùng thấm, gỉ hiếm khi lấp kín khung.
/// - Vết nứt: chiều dài ≈ đường chéo khung.
/// Đây là ước lượng; người kiểm kê sửa lại được trên phiếu. Model phân vùng
/// sẽ thay bằng diện tích và chiều dài theo mask.
class DamageMeasurer {
  const DamageMeasurer({
    required this.cropFraction,
    required this.damageTypeByClass,
    this.blobFill = math.pi / 4,
  });

  /// Tỉ lệ cạnh ô ảnh vào AI so với cạnh ngắn của ảnh camera.
  final double cropFraction;
  final Map<int, DamageType> damageTypeByClass;
  final double blobFill;

  FrameMeasurement measure({
    required List<Detection> detections,
    required double frameShortSidePx,
    MarkerScale? scale,
  }) {
    final cropSidePx = frameShortSidePx * cropFraction;
    final cmPerPx = scale?.cmPerPixel;
    final canMeasure = cmPerPx != null && cropSidePx > 0;
    // Cạnh ô ảnh AI tính bằng mét.
    final cropSideM = canMeasure ? cropSidePx * cmPerPx / 100 : 0.0;

    var ignored = 0;
    final out = <DamageMeasurement>[];
    for (final d in detections) {
      final type = damageTypeByClass[d.classIndex];
      if (type == null) {
        ignored++;
        continue;
      }
      var quantity = 0.0;
      if (canMeasure) {
        quantity = type.unit == MeasureUnit.meter
            ? math.sqrt(d.w * d.w + d.h * d.h) * cropSideM
            : d.w * d.h * blobFill * cropSideM * cropSideM;
      }
      out.add(
        DamageMeasurement(
          type: type,
          quantity: _round(quantity),
          confidence: d.score,
        ),
      );
    }
    return FrameMeasurement(
      measurements: List.unmodifiable(out),
      scale: canMeasure ? scale : null,
      capturedAreaM2: canMeasure ? _round(cropSideM * cropSideM) : null,
      ignoredDetections: ignored,
    );
  }

  /// Làm tròn 2 chữ số (0,01 m² / 1 cm) cho dễ đọc và dễ sửa trên phiếu.
  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
