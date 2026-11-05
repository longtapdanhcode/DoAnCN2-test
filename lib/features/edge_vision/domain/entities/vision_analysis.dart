/// Trạng thái mô hình AI trên máy.
enum VisionModelStatus {
  /// Chưa nạp (màn Quét chưa mở lần nào).
  notLoaded('Chưa nạp'),

  /// Đã nạp, sẵn sàng nhận diện.
  loaded('Đã nạp'),

  /// Tệp mô hình trống (bản placeholder), AI tắt.
  missing('Thiếu tệp mô hình'),

  /// Nạp lỗi, xem [VisionAiRepository.modelError].
  failed('Nạp lỗi');

  const VisionModelStatus(this.label);

  final String label;
}

/// Kết quả nhận diện một khung hình, kèm số liệu chẩn đoán.
class VisionAnalysis {
  const VisionAnalysis({
    this.labels = const [],
    this.topLabel,
    this.topScore = 0,
    this.topThreshold = 0,
    this.frameWidth = 0,
    this.frameHeight = 0,
    this.elapsed = Duration.zero,
    this.preprocessTime = Duration.zero,
    this.inferenceTime = Duration.zero,
    this.backend = '',
  });

  /// Nhãn đạt ngưỡng, dạng "Ghế (93.4%)", điểm cao xếp trước.
  final List<String> labels;

  /// Nhãn có điểm cao nhất, kể cả khi dưới ngưỡng.
  final String? topLabel;
  final double topScore;

  /// Ngưỡng áp cho [topLabel].
  final double topThreshold;

  /// Kích thước ảnh camera AI nhận được (sau khi giải mã JPEG).
  final int frameWidth;
  final int frameHeight;

  /// Thời gian giải mã + chạy mô hình cho khung này.
  final Duration elapsed;

  /// Phần thời gian giải mã + cắt khung + chuẩn hoá ảnh.
  final Duration preprocessTime;

  /// Phần thời gian chạy mô hình.
  final Duration inferenceTime;

  /// Phần cứng chạy mô hình, ví dụ "GPU (Metal)" hoặc "CPU 4 luồng".
  final String backend;

  bool get topPassed => topLabel != null && topScore >= topThreshold;
}
