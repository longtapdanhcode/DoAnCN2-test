import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

/// Provider cung cấp instance [SupabaseClient] toàn cục cho toàn bộ ứng dụng.
///
/// Được khai báo `keepAlive: true` để giữ kết nối và trạng thái Auth xuyên suốt.
/// Trong môi trường kiểm thử, có thể dễ dàng override bằng MockSupabaseClient:
/// ```dart
/// container = ProviderContainer(
///   overrides: [
///     supabaseClientProvider.overrideWithValue(mockClient),
///   ],
/// );
/// ```
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}
