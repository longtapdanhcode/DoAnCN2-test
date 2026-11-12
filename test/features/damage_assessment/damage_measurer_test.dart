import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/core/ai_pipeline/ai_config.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_measurer.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/entities/detection.dart';

Detection det(int cls, double w, double h, {double score = 0.9}) => Detection(
  classIndex: cls,
  label: '$cls',
  score: score,
  cx: 0.5,
  cy: 0.5,
  w: w,
  h: h,
);

void main() {
  const measurer = DamageMeasurer(
    cropFraction: 0.7,
    damageTypeByClass: AiConfig.damageTypeByClass,
  );

  group('MarkerScale', () {
    test('Thẻ 10 cm chiếm 200 px: 0,05 cm/px', () {
      final s = MarkerScale.fromCorners(const [
        Offset(100, 100),
        Offset(300, 100),
        Offset(300, 300),
        Offset(100, 300),
      ], 10)!;
      expect(s.markerSidePx, closeTo(200, 1e-9));
      expect(s.cmPerPixel, closeTo(0.05, 1e-9));
    });

    test('Không phụ thuộc chiều xoay của thẻ', () {
      // Thẻ xoay 45°, cạnh 200 px.
      final r = 200 / math.sqrt2;
      final s = MarkerScale.fromCorners([
        Offset(500, 500 - r),
        Offset(500 + r, 500),
        Offset(500, 500 + r),
        Offset(500 - r, 500),
      ], 10)!;
      expect(s.markerSidePx, closeTo(200, 1e-6));
    });

    test('Thiếu góc hoặc thẻ quá nhỏ: không đo', () {
      expect(MarkerScale.fromCorners(const [Offset(0, 0)], 10), isNull);
      expect(
        MarkerScale.fromCorners(const [
          Offset(0, 0),
          Offset(10, 0),
          Offset(10, 10),
          Offset(0, 10),
        ], 10),
        isNull,
      );
    });
  });

  group('DamageMeasurer', () {
    // Ảnh cạnh ngắn 1000 px, ô AI 700 px; 0,1 cm/px => ô AI cạnh 70 cm.
    const scale = MarkerScale(cmPerPixel: 0.1, markerSidePx: 100);

    test('Diện tích: khung × π/4, quy ra m²', () {
      final m = measurer.measure(
        detections: [det(2, 0.5, 0.5)], // thấm nước
        frameShortSidePx: 1000,
        scale: scale,
      );
      final item = m.measurements.single;
      expect(item.type, DamageType.waterMold);
      // 0.35 m × 0.35 m × π/4 ≈ 0.0962 m² => 0.10
      expect(item.quantity, 0.10);
      expect(item.confidence, 0.9);
      expect(m.capturedAreaM2, 0.49);
    });

    test('Vết nứt: chiều dài theo đường chéo khung', () {
      final m = measurer.measure(
        detections: [det(0, 0.6, 0.8)],
        frameShortSidePx: 1000,
        scale: scale,
      );
      // đường chéo 1.0 × 0.7 m
      expect(m.measurements.single.type, DamageType.crack);
      expect(m.measurements.single.quantity, 0.70);
    });

    test('Khuyết tật kim loại gộp vào gỉ sét; bàn ghế bị bỏ qua', () {
      final m = measurer.measure(
        detections: [det(5, 0.2, 0.2), det(1, 0.2, 0.2), det(6, 0.3, 0.3)],
        frameShortSidePx: 1000,
        scale: scale,
      );
      expect(m.measurements.map((e) => e.type), [
        DamageType.rust,
        DamageType.rust,
      ]);
      expect(m.ignoredDetections, 1);
    });

    test('Không có thẻ QR: vẫn liệt kê hư hỏng, số đo để 0', () {
      final m = measurer.measure(
        detections: [det(2, 0.5, 0.5)],
        frameShortSidePx: 1000,
      );
      expect(m.hasScale, isFalse);
      expect(m.measurements.single.quantity, 0);
      expect(m.capturedAreaM2, isNull);
    });
  });
}
