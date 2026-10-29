import '../entities/vision_analysis.dart';

abstract class VisionAiRepository {
  /// Nạp mô hình TFLite và danh sách nhãn vào bộ nhớ
  Future<void> loadModel();

  /// Trạng thái mô hình sau [loadModel].
  VisionModelStatus get modelStatus;

  /// Lỗi khi nạp mô hình (nếu có).
  String? get modelError;

  /// Số nhãn mô hình nhận diện được.
  int get labelCount;

  /// Nhận diện một khung ảnh JPEG, kèm số liệu chẩn đoán.
  Future<VisionAnalysis> analyze(List<int> imageBytes);

  /// Thực hiện inference on-device trên khung hình ảnh nhận diện vật thể
  Future<List<String>> analyzeFrame(
    List<int> imageBytes,
    int width,
    int height,
  );

  /// Giải phóng tài nguyên interpreter và tensors
  void close();
}
