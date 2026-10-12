import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../../core/ai_pipeline/ai_config.dart';
import '../../domain/repositories/vision_ai_repository.dart';

part 'tflite_vision_repository_impl.g.dart';

class TfliteVisionRepositoryImpl implements VisionAiRepository {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  @override
  Future<void> loadModel() async {
    try {
      // 1. Kiểm tra kích thước file model trước khi nạp vào C++ Interpreter
      final ByteData modelData = await rootBundle.load(AiConfig.modelPath);
      if (modelData.lengthInBytes == 0) {
        debugPrint(
          '[VisionAI] Model file is empty (placeholder), skipping AI inference',
        );
        _isModelLoaded = false;
        return;
      }

      // 2. Khởi tạo TFLite Interpreter từ assets
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        AiConfig.modelPath,
        options: options,
      );
      _isModelLoaded = true;
      debugPrint('[VisionAI] TFLite model loaded successfully');

      // 3. Đọc nhãn phân loại nếu có
      final String labelData = await rootBundle.loadString(AiConfig.labelPath);
      if (labelData.trim().isNotEmpty) {
        _labels = labelData
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[VisionAI] Model file is empty or invalid, skipping AI inference: $e',
      );
      _isModelLoaded = false;
    }
  }

  @override
  Future<List<String>> analyzeFrame(
    List<int> imageBytes,
    int width,
    int height,
  ) async {
    if (!_isModelLoaded || _interpreter == null) {
      return const [];
    }

    try {
      // Decode byte ảnh sang Image format
      final img.Image? decoded = img.decodeImage(
        Uint8List.fromList(imageBytes),
      );
      if (decoded == null) {
        return const [];
      }

      // Resize hình ảnh về kích thước chuẩn của input tensor
      final img.Image resized = img.copyResize(
        decoded,
        width: AiConfig.inputSize,
        height: AiConfig.inputSize,
      );

      // Chuẩn hóa tensor ảnh (ví dụ 1 x 224 x 224 x 3 Float32)
      final input = List.generate(
        1,
        (_) => List.generate(
          AiConfig.inputSize,
          (y) => List.generate(
            AiConfig.inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      // Chuẩn bị output buffer
      final outputLength = _labels.isNotEmpty ? _labels.length : 10;
      final output = [List<double>.filled(outputLength, 0.0)];

      // Chạy inference
      _interpreter!.run(input, output);

      // Trích xuất kết quả nhận diện vượt ngưỡng confidenceThreshold
      final results = <String>[];
      final scores = output[0];
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] >= AiConfig.confidenceThreshold) {
          final label = _labels.length > i ? _labels[i] : 'Object #$i';
          results.add(
            '$label (${(scores[i] * 100).toStringAsFixed(1)}%)',
          );
        }
      }

      return results;
    } catch (e) {
      debugPrint('[VisionAI] analyzeFrame error: $e');
      return const [];
    }
  }

  @override
  void close() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}

@riverpod
VisionAiRepository visionAiRepository(Ref ref) {
  final repository = TfliteVisionRepositoryImpl();
  ref.onDispose(() {
    repository.close();
  });
  return repository;
}
