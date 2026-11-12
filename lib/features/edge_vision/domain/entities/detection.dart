import 'package:flutter/foundation.dart';

/// Một vùng mô hình phát hiện trong ảnh vào AI (ô vuông giữa khung quét).
///
/// Toạ độ chuẩn hoá 0..1 theo cạnh ô vuông: (0, 0) là góc trên trái.
@immutable
class Detection {
  const Detection({
    required this.classIndex,
    required this.label,
    required this.score,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
  });

  final int classIndex;
  final String label;
  final double score;
  final double cx;
  final double cy;
  final double w;
  final double h;

  double get left => cx - w / 2;
  double get top => cy - h / 2;
  double get right => cx + w / 2;
  double get bottom => cy + h / 2;
  double get area => w * h;

  /// Tỉ lệ giao trên hợp (IoU) với [other].
  double iou(Detection other) {
    final iw = _overlap(left, right, other.left, other.right);
    final ih = _overlap(top, bottom, other.top, other.bottom);
    final inter = iw * ih;
    final union = area + other.area - inter;
    return union <= 0 ? 0 : inter / union;
  }

  static double _overlap(double a0, double a1, double b0, double b1) {
    final lo = a0 > b0 ? a0 : b0;
    final hi = a1 < b1 ? a1 : b1;
    return hi > lo ? hi - lo : 0;
  }

  @override
  String toString() =>
      'Detection($label ${(score * 100).toStringAsFixed(1)}% '
      'cx=${cx.toStringAsFixed(3)} cy=${cy.toStringAsFixed(3)} '
      'w=${w.toStringAsFixed(3)} h=${h.toStringAsFixed(3)})';
}
