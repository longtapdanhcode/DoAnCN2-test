import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_inventory_edge_ai/core/network/supabase_config.dart';
import 'package:field_inventory_edge_ai/core/network/supabase_provider.dart';

import '../data/supabase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!SupabaseConfig.isConfigured) return const UnconfiguredAuthRepository();
  try {
    return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
  } catch (e) {
    // Supabase khởi tạo lỗi (xem initSupabase): không đăng nhập được.
    debugPrint('[Auth] Supabase chưa sẵn sàng: $e');
    return const UnconfiguredAuthRepository();
  }
});

/// Tài khoản đang đăng nhập; `null` khi chưa đăng nhập.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchUser();
});

/// Tài khoản hiện tại để hiển thị ngay (không chờ luồng phát giá trị đầu).
final signedInUserProvider = Provider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return ref.watch(currentUserProvider).value ?? repo.currentUser;
});
