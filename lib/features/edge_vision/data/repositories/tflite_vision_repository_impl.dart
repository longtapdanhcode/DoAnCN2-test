import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// Phần cứng đang chạy mô hình, hiện ở thẻ Chẩn đoán AI.
  String _backend = '';

  /// Đã gọi [close]: không nhận khung mới nữa.
  bool _closed = false;

  /// Lượt suy luận đang chạy trong isolate (nếu có).
  Future<void>? _inference;

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

      // 2. Khởi tạo TFLite Interpreter từ assets (ưu tiên GPU)
      _interpreter = await _createInterpreter();
      // Suy luận chạy ở isolate riêng để không làm giật giao diện camera.
      _isolateInterpreter = await IsolateInterpreter.create(
        address: _interpreter!.address,
      );
      // Rời màn Quét trong lúc đang nạp: giải phóng ngay, không dùng nữa.
      if (_closed) {
        _release();
        return;
      }
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

  /// iOS: thử GPU Metal trước (nhanh hơn CPU nhiều lần với YOLOv8s), lỗi thì
  /// quay về CPU. CPU dùng 4 luồng thay vì 2.
  Future<Interpreter> _createInterpreter() async {
    if (Platform.isIOS) {
      try {
        final options = InterpreterOptions()
          ..addDelegate(
            GpuDelegate(
              options: GpuDelegateOptions(
                // Cho phép tính FP16 trên GPU: nhanh hơn, sai số không đáng kể
                // với điểm tin cậy.
                allowPrecisionLoss: true,
              ),
            ),
          );
        final interpreter = await Interpreter.fromAsset(
          AiConfig.modelPath,
          options: options,
        );
        _backend = 'GPU (Metal)';
        return interpreter;
      } catch (e) {
        debugPrint('[VisionAI] Metal delegate lỗi, chuyển sang CPU: $e');
      }
    }
    final interpreter = await Interpreter.fromAsset(
      AiConfig.modelPath,
      options: InterpreterOptions()..threads = 4,
    );
    _backend = 'CPU 4 luồng';
    return interpreter;
  }

  @override
  Future<List<String>> analyzeFrame(
    List<int> imageBytes,
    int width,
    int height,
  ) async => (await analyze(imageBytes)).labels;

  @override
  Future<VisionAnalysis> analyze(
    List<int> imageBytes, {
    Uint8List? squareRgb,
    int frameWidth = 0,
    int frameHeight = 0,
  }) async {
    if (_closed || !_isModelLoaded || _isolateInterpreter == null) {
      return const VisionAnalysis();
    }

    final watch = Stopwatch()..start();
    try {
      const size = AiConfig.inputSize;
      final Float32List input;
      if (squareRgb != null && squareRgb.length == size * size * 3) {
        // iOS đã cắt + thu nhỏ theo khung quét ở phía native.
        input = rgbToInputTensor(squareRgb);
      } else {
        // Nền tảng khác: giải mã JPEG bằng bộ giải mã native của Flutter,
        // thu nhỏ ngay lúc giải mã, rồi cắt phần giữa theo khung xanh.
        final bytes = imageBytes is Uint8List
            ? imageBytes
            : Uint8List.fromList(imageBytes);
        final decoded = await _decodeScaled(bytes);
        if (decoded == null) return const VisionAnalysis();
        final (rgba, scaledWidth, scaledHeight, width, height) = decoded;
        input = rgbaToInputTensor(rgba, scaledWidth, scaledHeight);
        frameWidth = width;
        frameHeight = height;
      }
      final preprocessTime = watch.elapsed;
      final interpreter = _isolateInterpreter;
      if (_closed || interpreter == null) return const VisionAnalysis();

      final channels = 4 + _labels.length;
      final output = Float32List(channels * _anchorCount);
      final run = interpreter.run(input.buffer, output.buffer);
      _inference = run;
      try {
        await run;
      } finally {
        _inference = null;
      }
      final inferenceTime = watch.elapsed - preprocessTime;

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
        preprocessTime: preprocessTime,
        inferenceTime: inferenceTime,
        backend: _backend,
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

  /// Giải mã JPEG bằng bộ giải mã native, thu nhỏ sao cho phần khung xanh
  /// ([AiConfig.cropFraction] cạnh ngắn) vừa đúng [AiConfig.inputSize].
  /// Trả về (RGBA, rộng, cao sau thu nhỏ, rộng, cao ảnh gốc).
  static Future<(Uint8List, int, int, int, int)?> _decodeScaled(
    Uint8List jpeg,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(jpeg);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      final crop = math.min(width, height) * AiConfig.cropFraction;
      final scale = AiConfig.inputSize / crop;
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (width * scale).round()),
        targetHeight: math.max(1, (height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return null;
      return (
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        image.width,
        image.height,
        width,
        height,
      );
    } catch (e) {
      debugPrint('[VisionAI] Không giải mã được khung: $e');
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  /// Ảnh RGB [AiConfig.inputSize]² (từ native) sang tensor float32 NCHW, 0..1.
  @visibleForTesting
  static Float32List rgbToInputTensor(Uint8List rgb) {
    const plane = AiConfig.inputSize * AiConfig.inputSize;
    const inv = 1 / 255.0;
    final data = Float32List(3 * plane);
    for (var i = 0, p = 0; i < plane; i++, p += 3) {
      data[i] = rgb[p] * inv;
      data[plane + i] = rgb[p + 1] * inv;
      data[2 * plane + i] = rgb[p + 2] * inv;
    }
    return data;
  }

  /// Cắt ô vuông [AiConfig.inputSize] ở giữa ảnh RGBA rồi chuyển sang tensor
  /// float32 NCHW 1x3x640x640, giá trị 0..1. Phần thiếu (ảnh nhỏ hơn ô) tô
  /// xám 114 như letterbox lúc huấn luyện.
  @visibleForTesting
  static Float32List rgbaToInputTensor(Uint8List rgba, int width, int height) {
    const size = AiConfig.inputSize;
    const plane = size * size;
    const pad = 114 / 255.0;
    const inv = 1 / 255.0;
    final data = Float32List(3 * plane);
    // Gốc ô cắt trong ảnh nguồn (âm khi ảnh nhỏ hơn ô).
    final x0 = (width - size) ~/ 2;
    final y0 = (height - size) ~/ 2;
    for (var y = 0; y < size; y++) {
      final sy = y + y0;
      final rowInside = sy >= 0 && sy < height;
      for (var x = 0; x < size; x++) {
        final i = y * size + x;
        final sx = x + x0;
        if (rowInside && sx >= 0 && sx < width) {
          final p = (sy * width + sx) * 4;
          data[i] = rgba[p] * inv;
          data[plane + i] = rgba[p + 1] * inv;
          data[2 * plane + i] = rgba[p + 2] * inv;
        } else {
          data[i] = pad;
          data[plane + i] = pad;
          data[2 * plane + i] = pad;
        }
      }
    }
    return data;
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
    _closed = true;
    _isModelLoaded = false;
    // Không giải phóng mô hình khi isolate còn đang chạy trên nó: bộ nhớ
    // native bị xoá giữa chừng làm iOS tắt app (bấm quay lại lúc AI đang xử
    // lý một khung). Chờ lượt đó xong rồi mới giải phóng.
    final running = _inference;
    if (running == null) {
      _release();
    } else {
      unawaited(running.catchError((Object _) {}).whenComplete(_release));
    }
  }

  void _release() {
    _isolateInterpreter?.close();
    _isolateInterpreter = null;
    _interpreter?.close();
    _interpreter = null;
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
