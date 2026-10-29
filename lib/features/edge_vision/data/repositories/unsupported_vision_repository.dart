import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vision_analysis.dart';
import '../../domain/repositories/vision_ai_repository.dart';

/// Bộ AI cho nền tảng không chạy được TFLite (bản web): luôn trả rỗng.
class UnsupportedVisionRepository implements VisionAiRepository {
  const UnsupportedVisionRepository();

  @override
  Future<void> loadModel() async {}

  @override
  VisionModelStatus get modelStatus => VisionModelStatus.missing;

  @override
  String? get modelError => 'Bản web không chạy AI trên thiết bị.';

  @override
  int get labelCount => 0;

  @override
  Future<VisionAnalysis> analyze(List<int> imageBytes) async =>
      const VisionAnalysis();

  @override
  Future<List<String>> analyzeFrame(List<int> b, int w, int h) async =>
      const [];

  @override
  void close() {}
}

final visionAiRepositoryProvider = Provider.autoDispose<VisionAiRepository>(
  (ref) => const UnsupportedVisionRepository(),
);
