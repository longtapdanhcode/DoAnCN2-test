abstract class VisionAiRepository {
  /// Nạp mô hình TFLite và danh sách nhãn vào bộ nhớ
  Future<void> loadModel();

  /// Thực hiện inference on-device trên khung hình ảnh nhận diện vật thể
  Future<List<String>> analyzeFrame(List<int> imageBytes, int width, int height);

  /// Giải phóng tài nguyên interpreter và tensors
  void close();
}
