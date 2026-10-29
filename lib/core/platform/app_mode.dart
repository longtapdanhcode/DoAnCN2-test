import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cách app chạy (Card 28).
enum AppMode {
  /// App điện thoại ở hiện trường: quét mã, AI, lập phiếu, lưu ngoại tuyến.
  field,

  /// Bản web: trung tâm quản lý dữ liệu đọc/ghi thẳng trên Supabase,
  /// không quét camera và không lưu ngoại tuyến.
  console;

  /// Có quét mã, nhận diện AI, lập và ký phiếu trên máy này không.
  bool get canScan => this == field;
}

/// Bản web chạy chế độ quản lý; test có thể override.
final appModeProvider = Provider<AppMode>(
  (ref) => kIsWeb ? AppMode.console : AppMode.field,
);

/// Đường dẫn chỉ có trên app điện thoại (quét, lập phiếu, ký, đồng bộ ngoại tuyến).
const fieldOnlyPaths = ['/scanner', '/audit-form', '/signature', '/sync'];

bool isFieldOnlyPath(String path) =>
    fieldOnlyPaths.any((p) => path == p || path.startsWith('$p/'));
