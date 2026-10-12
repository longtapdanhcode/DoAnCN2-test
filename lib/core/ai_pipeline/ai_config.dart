class AiConfig {
  const AiConfig._();

  /// Đường dẫn asset tới model TFLite nhận diện vật thể
  static const String modelPath = 'assets/models/object_detection.tflite';

  /// Đường dẫn asset tới file nhãn phân loại (labels)
  static const String labelPath = 'assets/models/labels.txt';

  /// Kích thước cạnh đầu vào của model (224x224 chuẩn cho MobileNet / EfficientNet)
  static const int inputSize = 224;

  /// Ngưỡng độ tin cậy tối thiểu để chấp nhận kết quả nhận diện
  static const double confidenceThreshold = 0.5;
}
