import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lớp cấu hình Supabase chứa URL và Public Anon Key.
///
/// Các giá trị mặc định là chuỗi rỗng `''` (placeholder),
/// bạn hãy thay thế bằng thông tin thực tế từ Supabase Dashboard:
/// Project Settings -> API.
class SupabaseConfig {
  const SupabaseConfig._();

  /// URL kết nối Supabase Project (ví dụ: 'https://xyzcompany.supabase.co').
  static const String url = 'https://ksyqadzajepmrgaoweyi.supabase.co/rest/v1/';

  /// Public Anonymous / Publishable Key của Supabase Project.
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzeXFhZHphamVwbXJnYW93ZXlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzNzYxMTEsImV4cCI6MjEwNTk1MjExMX0.Oe4TMBQ2ZiTbZPv8D4qgBlO6XoQEoctYAl9imf66NOE';

  /// Alias publishableKey theo chuẩn mới của Supabase SDK.
  static String get publishableKey => anonKey;

  /// Kiểm tra xem cấu hình Supabase đã được điền thông tin hợp lệ hay chưa.
  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}

/// Khởi tạo Supabase client toàn cục cho ứng dụng.
///
/// Được gọi trong `main()` sau `WidgetsFlutterBinding.ensureInitialized()`.
/// Nếu chưa cấu hình URL hoặc Anon Key, hàm sẽ ghi nhận cảnh báo và bỏ qua
/// để không làm gián đoạn tiến trình khởi động của app (Offline-First).
Future<void> initSupabase() async {
  if (!SupabaseConfig.isConfigured) {
    if (kDebugMode) {
      debugPrint(
        '[Supabase] Cảnh báo: SupabaseConfig.url hoặc anonKey đang để trống. '
        'Bỏ qua khởi tạo Supabase. Vui lòng cấu hình key thật trong supabase_config.dart.',
      );
    }
    return;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    if (kDebugMode) {
      debugPrint('[Supabase] Khởi tạo Supabase thành công.');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('[Supabase] Lỗi khi khởi tạo Supabase: $e\n$stackTrace');
    }
  }
}
