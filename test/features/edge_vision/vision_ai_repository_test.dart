import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/core/ai_pipeline/ai_config.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiConfig Tests', () {
    test('AiConfig constants are properly configured', () {
      expect(AiConfig.modelPath, 'assets/models/object_detection.tflite');
      expect(AiConfig.labelPath, 'assets/models/labels.txt');
      expect(AiConfig.inputSize, 640);
      expect(AiConfig.confidenceThreshold, 0.5);
    });
  });

  group('TfliteVisionRepositoryImpl Safe Fallback Tests', () {
    test('analyzeFrame returns empty list when model is not loaded', () async {
      final repo = TfliteVisionRepositoryImpl();
      expect(repo.isModelLoaded, isFalse);

      final result = await repo.analyzeFrame([0, 1, 2, 3], 224, 224);
      expect(result, isEmpty);

      repo.close();
      expect(repo.isModelLoaded, isFalse);
    });
  });

  group('decodeDetections', () {
    const labels = [
      'Vết nứt',
      'Gỉ sét',
      'Thấm nước',
      'Tủ điện',
      'Aptomat',
      'Khuyết tật kim loại',
      'Ghế',
      'Bàn',
      'Máy chiếu',
    ];

    /// Đầu ra giả: 4 hàng hộp + 9 hàng điểm lớp, 3 ô dự đoán.
    List<List<double>> output(Map<int, List<double>> scores) => [
      for (var r = 0; r < 4; r++) [0.5, 0.5, 0.5],
      for (var c = 0; c < labels.length; c++) scores[c] ?? [0.0, 0.0, 0.0],
    ];

    test('lấy điểm cao nhất mỗi nhãn và sắp xếp giảm dần', () {
      final result = TfliteVisionRepositoryImpl.decodeDetections(
        output({
          3: [0.2, 0.9, 0.6],
          6: [0.8, 0.1, 0.0],
        }),
        labels,
      );
      expect(result, ['Tủ điện (90.0%)', 'Ghế (80.0%)']);
    });

    test('nhóm hư hỏng dùng ngưỡng cao hơn thiết bị', () {
      final result = TfliteVisionRepositoryImpl.decodeDetections(
        output({
          0: [0.6, 0.0, 0.0],
          7: [0.6, 0.0, 0.0],
        }),
        labels,
      );
      expect(result, ['Bàn (60.0%)']);
    });

    test('không có kết quả nào vượt ngưỡng', () {
      expect(
        TfliteVisionRepositoryImpl.decodeDetections(
          output({
            3: [0.3, 0.2, 0.1],
          }),
          labels,
        ),
        isEmpty,
      );
    });
  });
}
