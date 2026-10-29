import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Dịch lỗi của Supabase Auth sang câu tiếng Việt.
@visibleForTesting
String describeAuthError(Object error) {
  if (error is AuthRetryableFetchException ||
      error is SocketException ||
      error is TimeoutException) {
    return 'Không kết nối được máy chủ. Cần có mạng để đăng nhập hoặc đăng ký.';
  }
  if (error is AuthException) {
    final code = error.code ?? '';
    final msg = error.message.toLowerCase();
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return 'Email chưa được xác nhận. Mở thư xác nhận rồi đăng nhập lại.';
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return 'Email này đã có tài khoản. Hãy đăng nhập.';
    }
    if (code == 'weak_password' || msg.contains('password should be')) {
      return 'Mật khẩu quá yếu, cần ít nhất 6 ký tự.';
    }
    if (code == 'over_email_send_rate_limit' || msg.contains('rate limit')) {
      return 'Gửi yêu cầu quá nhiều lần. Vui lòng thử lại sau ít phút.';
    }
    if (code == 'signup_disabled') {
      return 'Dự án đang tắt đăng ký tài khoản mới.';
    }
    return error.message;
  }
  return 'Đã có lỗi: $error';
}

/// [AuthRepository] dùng Supabase Auth; hồ sơ (họ tên, vai trò) đọc từ bảng
/// `profiles` và lưu tạm trên máy để dùng khi ngoại tuyến.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;
  AppUser? _profile;

  GoTrueClient get _auth => _client.auth;

  AppUser? _fromSession(User? user) {
    if (user == null) return null;
    final cached = _profile;
    if (cached != null && cached.id == user.id) return cached;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String? ?? '',
    );
  }

  @override
  AppUser? get currentUser => _fromSession(_auth.currentUser);

  /// Phát khi hồ sơ vừa tải từ máy chủ khác bản đang dùng.
  final _profileChanges = StreamController<void>.broadcast();

  @override
  Stream<AppUser?> watchUser() {
    StreamSubscription<AuthState>? authSub;
    StreamSubscription<void>? profileSub;
    late final StreamController<AppUser?> controller;
    controller = StreamController<AppUser?>(
      onListen: () async {
        await _loadCachedProfile();
        controller.add(currentUser);
        authSub = _auth.onAuthStateChange.listen((event) {
          if (event.event == AuthChangeEvent.signedIn) {
            unawaited(_refreshProfile());
          }
          controller.add(_fromSession(event.session?.user));
        }, onError: controller.addError);
        profileSub = _profileChanges.stream.listen(
          (_) => controller.add(currentUser),
        );
        unawaited(_refreshProfile());
      },
      onCancel: () async {
        await authSub?.cancel();
        await profileSub?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> _refreshProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final row = await _client
          .from('profiles')
          .select('full_name, role')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return;
      final next = AppUser(
        id: user.id,
        email: user.email ?? '',
        fullName: row['full_name'] as String? ?? '',
        role: UserRole.fromCode(row['role'] as String?),
      );
      if (next != _profile) {
        _profile = next;
        _profileChanges.add(null);
        await _saveCachedProfile(next);
      }
    } catch (e) {
      debugPrint('[Auth] Chưa tải được hồ sơ (dùng bản trên máy): $e');
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } catch (e) {
      throw AuthFailure(describeAuthError(e));
    }
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      // Supabase không báo lỗi khi email đã tồn tại (để tránh dò email):
      // khi đó user trả về không có danh tính nào.
      if (res.user != null && (res.user!.identities ?? const []).isEmpty) {
        throw const AuthFailure('Email này đã có tài khoản. Hãy đăng nhập.');
      }
      return res.session != null
          ? SignUpOutcome.signedIn
          : SignUpOutcome.confirmEmail;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(describeAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    _profile = null;
    await _deleteCachedProfile();
    // Chỉ xoá phiên trên máy: đăng xuất được cả khi đang ngoại tuyến.
    await _auth.signOut(scope: SignOutScope.local);
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/account_profile.json');
  }

  Future<void> _loadCachedProfile() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return;
      _profile = AppUser(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        role: UserRole.fromCode(json['role'] as String?),
      );
    } catch (e) {
      debugPrint('[Auth] Không đọc được hồ sơ trên máy: $e');
    }
  }

  Future<void> _saveCachedProfile(AppUser user) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(
        jsonEncode({
          'id': user.id,
          'email': user.email,
          'full_name': user.fullName,
          'role': user.role.code,
        }),
      );
    } catch (e) {
      debugPrint('[Auth] Không lưu được hồ sơ trên máy: $e');
    }
  }

  Future<void> _deleteCachedProfile() async {
    try {
      final file = await _cacheFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Dùng khi chưa cấu hình Supabase: không ai đăng nhập được.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  static const _message =
      'Chưa cấu hình Supabase (lib/core/network/supabase_config.dart).';

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> watchUser() => Stream.value(null);

  @override
  Future<void> signIn({required String email, required String password}) =>
      Future.error(const AuthFailure(_message));

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  }) => Future.error(const AuthFailure(_message));

  @override
  Future<void> signOut() async {}
}
