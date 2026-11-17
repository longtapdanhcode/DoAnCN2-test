import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/edge_vision/domain/entities/detection.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/yolo_box_decoder.dart';

/// Dựng đầu ra YOLO [4 + lớp][ô] từ danh sách ô (cx, cy, w, h, điểm từng lớp).
List<List<double>> output(List<List<double>> anchors, int classes) => [
  for (var c = 0; c < 4 + classes; c++) [for (final a in anchors) a[c]],
];

void main() {
  const labels = ['Vết nứt', 'Gỉ sét', 'Ghế'];
  double threshold(int c) => c == 2 ? 0.5 : 0.7;

  test('Giữ ô đạt ngưỡng theo lớp có điểm cao nhất', () {
    final out = output([
      [0.5, 0.5, 0.2, 0.1, 0.9, 0.1, 0.0], // nứt 0.9
      [0.2, 0.2, 0.1, 0.1, 0.65, 0.0, 0.0], // nứt 0.65 < 0.7: bỏ
      [0.8, 0.8, 0.1, 0.1, 0.0, 0.0, 0.55], // ghế 0.55 >= 0.5
    ], 3);
    final d = decodeYoloBoxes(out, labels, thresholdFor: threshold);
    expect(d.map((e) => e.label), ['Vết nứt', 'Ghế']);
    expect(d.first.cx, closeTo(0.5, 1e-9));
    expect(d.first.w, closeTo(0.2, 1e-9));
  });

  test('NMS bỏ khung trùng cùng lớp, giữ khung khác lớp', () {
    final out = output([
      [0.5, 0.5, 0.4, 0.4, 0.95, 0, 0],
      [0.51, 0.5, 0.4, 0.4, 0.9, 0, 0], // trùng khung trên
      [0.5, 0.5, 0.4, 0.4, 0, 0.92, 0], // cùng chỗ nhưng lớp khác
      [0.1, 0.1, 0.1, 0.1, 0.8, 0, 0], // xa: giữ
    ], 3);
    final d = decodeYoloBoxes(out, labels, thresholdFor: threshold);
    expect(d, hasLength(3));
    expect(d.where((e) => e.classIndex == 0), hasLength(2));
  });

  test('Toạ độ theo pixel được chuẩn hoá về 0..1', () {
    final out = output([
      [320, 320, 64, 128, 0.9, 0, 0],
    ], 3);
    final d = decodeYoloBoxes(out, labels, thresholdFor: threshold).single;
    expect(d.cx, closeTo(0.5, 1e-9));
    expect(d.w, closeTo(0.1, 1e-9));
    expect(d.h, closeTo(0.2, 1e-9));
  });

  test('Khung tràn mép bị cắt về trong ảnh', () {
    final out = output([
      [0.05, 0.5, 0.2, 0.2, 0.9, 0, 0],
    ], 3);
    final d = decodeYoloBoxes(out, labels, thresholdFor: threshold).single;
    expect(d.left, closeTo(0, 1e-9));
    expect(d.w, closeTo(0.15, 1e-9));
  });

  test('keepClass và maxDetections giới hạn kết quả', () {
    final out = output([
      for (var i = 0; i < 10; i++)
        [i / 10 + 0.05, 0.5, 0.05, 0.05, 0.9, 0, 0.9],
    ], 3);
    final d = decodeYoloBoxes(
      out,
      labels,
      thresholdFor: threshold,
      keepClass: (c) => c != 2,
      maxDetections: 4,
    );
    expect(d, hasLength(4));
    expect(d.every((e) => e.classIndex == 0), isTrue);
  });

  test('Đầu ra thiếu kênh: không có kết quả', () {
    expect(
      decodeYoloBoxes(
        [
          [0.5],
        ],
        labels,
        thresholdFor: threshold,
      ),
      isEmpty,
    );
  });

  test('IoU của hai khung', () {
    const a = Detection(
      classIndex: 0,
      label: '',
      score: 1,
      cx: 0.5,
      cy: 0.5,
      w: 0.2,
      h: 0.2,
    );
    const b = Detection(
      classIndex: 0,
      label: '',
      score: 1,
      cx: 0.6,
      cy: 0.5,
      w: 0.2,
      h: 0.2,
    );
    // Giao 0.1 × 0.2 = 0.02; hợp 0.04 + 0.04 - 0.02 = 0.06.
    expect(a.iou(b), closeTo(1 / 3, 1e-9));
    expect(a.iou(a), closeTo(1, 1e-9));
  });
}
