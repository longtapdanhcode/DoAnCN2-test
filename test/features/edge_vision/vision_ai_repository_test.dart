import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/core/ai_pipeline/ai_config.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiConfig Tests', () {
    test('AiConfig constants are properly configured', () {
      expect(AiConfig.modelPath, 'assets/models/object_detection.tflite');
      expect(AiConfig.labelPath, 'assets/models/labels.txt');
      expect(AiConfig.inputSize, 224);
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
}
