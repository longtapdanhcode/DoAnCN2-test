class AiConfig {
  const AiConfig._();

  /// Mô hình YOLO (best.pt) đã xuất sang TFLite, đầu vào 1x3x640x640 (NCHW),
  /// đầu ra 1x(4+số lớp)x8400: cx, cy, w, h (chuẩn hoá 0..1) rồi điểm từng lớp.
  static const String modelPath = 'assets/models/object_detection.tflite';

  /// Nhãn hiển thị, đúng thứ tự lớp lúc huấn luyện:
  /// crack, rust, water_damage, electric_panel, circuit_breaker, metal_defect,
  /// chair, table, projector.
  static const String labelPath = 'assets/models/labels.txt';

  /// Kích thước cạnh đầu vào của mô hình.
  static const int inputSize = 640;

  /// Ngưỡng tin cậy cho nhóm thiết bị.
  static const double confidenceThreshold = 0.5;

  /// Ngưỡng cao hơn cho nhóm hư hỏng (vết nứt, gỉ, thấm nước, khuyết tật kim
  /// loại): ma trận nhầm lẫn cho thấy các lớp này báo thừa nhiều ở vùng nền.
  static const double defectConfidenceThreshold = 0.7;

  /// Chỉ số các lớp hư hỏng trong danh sách nhãn.
  static const Set<int> defectClassIndexes = {0, 1, 2, 5};
}
