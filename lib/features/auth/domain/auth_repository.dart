import 'app_user.dart';

/// Kết quả đăng ký.
enum SignUpOutcome {
  /// Đã đăng nhập luôn (dự án tắt xác nhận email).
  signedIn,

  /// Cần mở email xác nhận rồi mới đăng nhập được.
  confirmEmail,
}

/// Lỗi đăng nhập/đăng ký đã dịch sang câu dễ hiểu cho người dùng.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Đăng nhập bằng Supabase Auth (Card 26).
///
/// Phiên đăng nhập được lưu trên máy, nên sau lần đầu (cần mạng) app vẫn
/// dùng được khi ngoại tuyến cho tới khi đăng xuất.
abstract class AuthRepository {
  /// Tài khoản đang đăng nhập, `null` nếu chưa đăng nhập.
  AppUser? get currentUser;

  /// Phát tài khoản hiện tại rồi phát lại mỗi khi đăng nhập/đăng xuất.
  Stream<AppUser?> watchUser();

  /// Ném [AuthFailure] nếu không đăng nhập được.
  Future<void> signIn({required String email, required String password});

  /// Tạo tài khoản kiểm kê viên mới. Ném [AuthFailure] nếu không tạo được.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Đăng xuất trên máy này (dữ liệu kiểm kê trên máy vẫn giữ nguyên).
  Future<void> signOut();
}
