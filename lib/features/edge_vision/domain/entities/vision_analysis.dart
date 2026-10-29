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

  bool get topPassed => topLabel != null && topScore >= topThreshold;
}
