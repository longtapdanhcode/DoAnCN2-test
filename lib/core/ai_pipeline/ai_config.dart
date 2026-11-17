import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';

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

  /// Tỉ lệ cạnh khung xanh so với cạnh ngắn của ảnh camera. Màn Quét hiển thị
  /// camera kiểu cover nên khung xanh (~254pt trên khung xem ~366pt) chiếm
  /// khoảng 70% chiều ngang ảnh. AI chỉ nhận phần ảnh giữa này, bỏ chữ/giao
  /// diện xung quanh và bớt phải thu nhỏ ảnh.
  static const double cropFraction = 0.7;

  /// Ngưỡng tin cậy cho nhóm thiết bị.
  static const double confidenceThreshold = 0.5;

  /// Ngưỡng cao hơn cho nhóm hư hỏng (vết nứt, gỉ, thấm nước, khuyết tật kim
  /// loại): ma trận nhầm lẫn cho thấy các lớp này báo thừa nhiều ở vùng nền.
  static const double defectConfidenceThreshold = 0.7;

  /// Chỉ số các lớp hư hỏng trong danh sách nhãn.
  static const Set<int> defectClassIndexes = {0, 1, 2, 5};

  /// Lớp của model ứng với loại hư hỏng bề mặt nào. Model hiện tại (9 lớp)
  /// có 3 loại; "Khuyết tật kim loại" gộp vào gỉ sét. Khi thay model phân
  /// vùng 4 lớp mới, đổi thành `{0: crack, 1: waterMold, 2: peelingPaint,
  /// 3: rust}` (xem docs/ai-training/HUONG_DAN_TRAIN_MODEL_BE_MAT.md).
  static const Map<int, DamageType> damageTypeByClass = {
    0: DamageType.crack,
    1: DamageType.rust,
    2: DamageType.waterMold,
    5: DamageType.rust,
  };

  /// Ngưỡng IoU khi lọc các khung trùng nhau của cùng một lớp.
  static const double nmsIouThreshold = 0.45;

  /// Số khung tối đa giữ lại cho một khung hình.
  static const int maxDetections = 30;

  /// Cạnh thật (cm) của thẻ QR dán trên bề mặt, dùng để quy đổi pixel ra cm.
  static const double markerSizeCm = 10;
}
