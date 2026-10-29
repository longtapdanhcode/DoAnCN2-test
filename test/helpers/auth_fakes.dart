import 'dart:async';

import 'package:field_inventory_edge_ai/features/auth/domain/app_user.dart';
import 'package:field_inventory_edge_ai/features/auth/domain/auth_repository.dart';

const testUser = AppUser(
  id: 'u-1',
  email: 'an@fieldline.vn',
  fullName: 'Hoàng An',
);

/// Đăng nhập giả trong bộ nhớ, dùng cho test.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signedInAs}) : _user = signedInAs;

  /// Tài khoản đã có phiên trên máy lúc mở app (`null`: chưa đăng nhập).
  final AppUser? signedInAs;
  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  /// Lỗi ném ra ở lần signIn/signUp tiếp theo (nếu có).
  AuthFailure? nextFailure;

  SignUpOutcome signUpOutcome = SignUpOutcome.signedIn;
  String? lastEmail;
  String? lastPassword;
  String? lastFullName;

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchUser() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
    _set(AppUser(id: 'u-1', email: email.trim(), fullName: 'Hoàng An'));
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    lastEmail = email;
    lastPassword = password;
    lastFullName = fullName;
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
    if (signUpOutcome == SignUpOutcome.signedIn) {
      _set(AppUser(id: 'u-2', email: email.trim(), fullName: fullName.trim()));
    }
    return signUpOutcome;
  }

  @override
  Future<void> signOut() async => _set(null);
}
