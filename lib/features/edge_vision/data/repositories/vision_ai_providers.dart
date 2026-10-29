// Bản web không có dart:ffi nên không chạy được tflite_flutter: dùng bản
// thay thế báo AI không khả dụng (bản web không quét camera, Card 28).
export 'tflite_vision_repository_impl.dart'
    if (dart.library.js_interop) 'unsupported_vision_repository.dart';
