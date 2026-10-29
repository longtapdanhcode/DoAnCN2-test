import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../../core/ai_pipeline/ai_config.dart';
import '../../domain/entities/vision_analysis.dart';
import '../../domain/repositories/vision_ai_repository.dart';

part 'tflite_vision_repository_impl.g.dart';

class TfliteVisionRepositoryImpl implements VisionAiRepository {
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  VisionModelStatus _status = VisionModelStatus.notLoaded;
  String? _error;

  bool get isModelLoaded => _isModelLoaded;

  @override
  VisionModelStatus get modelStatus => _status;

  @override
  String? get modelError => _error;

  @override
  int get labelCount => _labels.length;

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
        _status = VisionModelStatus.missing;
        return;
      }

      // 2. Khởi tạo TFLite Interpreter từ assets
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        AiConfig.modelPath,
        options: options,
      );
      // Suy luận chạy ở isolate riêng để không làm giật giao diện camera.
      _isolateInterpreter = await IsolateInterpreter.create(
        address: _interpreter!.address,
      );
      _isModelLoaded = true;
      _status = VisionModelStatus.loaded;
      _error = null;
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
      _status = VisionModelStatus.failed;
      _error = '$e';
    }
  }

  @override
  Future<List<String>> analyzeFrame(
    List<int> imageBytes,
    int width,
    int height,
  ) async => (await analyze(imageBytes)).labels;

  @override
  Future<VisionAnalysis> analyze(List<int> imageBytes) async {
    if (!_isModelLoaded || _isolateInterpreter == null) {
      return const VisionAnalysis();
    }

    final watch = Stopwatch()..start();
    try {
      final bytes = Uint8List.fromList(imageBytes);
      // Giải mã JPEG + letterbox + chuẩn hoá nằm ngoài luồng giao diện.
      final prepared = await Isolate.run(() => _buildInputTensor(bytes));
      if (prepared == null) return const VisionAnalysis();
      final (input, frameWidth, frameHeight) = prepared;

      final channels = 4 + _labels.length;
      final output = Float32List(channels * _anchorCount);
      await _isolateInterpreter!.run(input.buffer, output.buffer);

      final rows = [
        for (var c = 0; c < channels; c++)
          Float32List.sublistView(
            output,
            c * _anchorCount,
            (c + 1) * _anchorCount,
          ),
      ];
      final top = topCandidate(rows, _labels.length);
      return VisionAnalysis(
        labels: decodeDetections(rows, _labels),
        topLabel: top == null ? null : _labels[top.$1],
        topScore: top?.$2 ?? 0,
        topThreshold: top == null ? 0 : thresholdFor(top.$1),
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        elapsed: watch.elapsed,
      );
    } catch (e) {
      debugPrint('[VisionAI] analyzeFrame error: $e');
      return VisionAnalysis(elapsed: watch.elapsed);
    }
  }

  /// Ngưỡng tin cậy của nhãn thứ [classIndex].
  static double thresholdFor(int classIndex) =>
      AiConfig.defectClassIndexes.contains(classIndex)
      ? AiConfig.defectConfidenceThreshold
      : AiConfig.confidenceThreshold;

  /// Nhãn có điểm cao nhất (chỉ số, điểm), kể cả khi dưới ngưỡng.
  @visibleForTesting
  static (int, double)? topCandidate(List<List<double>> output, int labels) {
    (int, double)? best;
    for (var c = 0; c < labels && 4 + c < output.length; c++) {
      for (final score in output[4 + c]) {
        if (best == null || score > best.$2) best = (c, score);
      }
    }
    return best;
  }

  /// Số ô dự đoán của YOLO ở đầu vào 640x640.
  static const int _anchorCount = 8400;

  /// Giải mã ảnh, letterbox về vuông (nền xám 114 như lúc huấn luyện) rồi
  /// chuyển sang tensor float32 dạng NCHW 1x3x640x640, giá trị 0..1.
  /// Chạy trong isolate nên phải là hàm tĩnh, không dùng trạng thái của lớp.
  static (Float32List, int, int)? _buildInputTensor(Uint8List jpeg) {
    final source = img.decodeImage(jpeg);
    if (source == null) return null;

    const size = AiConfig.inputSize;
    final scale =
        size / (source.width > source.height ? source.width : source.height);
    final w = (source.width * scale).round().clamp(1, size);
    final h = (source.height * scale).round().clamp(1, size);
    final resized = img.copyResize(source, width: w, height: h);
    final dx = (size - w) ~/ 2;
    final dy = (size - h) ~/ 2;

    const plane = size * size;
    final data = Float32List(3 * plane)..fillRange(0, 3 * plane, 114 / 255.0);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final pixel = resized.getPixel(x, y);
        final i = (y + dy) * size + (x + dx);
        data[i] = pixel.r / 255.0;
        data[plane + i] = pixel.g / 255.0;
        data[2 * plane + i] = pixel.b / 255.0;
      }
    }
    return (data, source.width, source.height);
  }

  /// Chọn kết quả từ đầu ra YOLO [channels][anchors]: mỗi nhãn lấy điểm cao
  /// nhất, bỏ qua nếu thấp hơn ngưỡng của nhóm, sắp xếp giảm dần theo điểm.
  @visibleForTesting
  static List<String> decodeDetections(
    List<List<double>> output,
    List<String> labels,
  ) {
    final best = <int, double>{};
    for (var c = 0; c < labels.length && 4 + c < output.length; c++) {
      final threshold = thresholdFor(c);
      var top = 0.0;
      for (final score in output[4 + c]) {
        if (score > top) top = score;
      }
      if (top >= threshold) best[c] = top;
    }
    final order = best.keys.toList()
      ..sort((a, b) => best[b]!.compareTo(best[a]!));
    return [
      for (final c in order)
        '${labels[c]} (${(best[c]! * 100).toStringAsFixed(1)}%)',
    ];
  }

  @override
  void close() {
    _isolateInterpreter?.close();
    _isolateInterpreter = null;
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
