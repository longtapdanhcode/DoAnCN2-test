import 'package:flutter/widgets.dart';

/// Vai trò tài khoản, khớp cột `profiles.role` trên Supabase.
enum UserRole {
  admin('admin', 'Quản trị viên'),
  auditor('auditor', 'Kiểm kê viên');

  const UserRole(this.code, this.label);

  final String code;
  final String label;

  static UserRole fromCode(String? code) =>
      code == admin.code ? admin : auditor;
}

/// Tài khoản đang đăng nhập trên máy.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName = '',
    this.role = UserRole.auditor,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  /// Tên hiển thị: họ tên, hoặc phần trước @ của email nếu chưa có họ tên.
  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : email.split('@').first;

  /// Hai chữ cái đầu cho ảnh đại diện (ví dụ "Hoàng An" -> "HA").
  String get initials {
    final words = displayName
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final picked = words.length == 1
        ? [words.first]
        : [words[words.length - 2], words.last];
    return picked.map((w) => w.characters.first.toUpperCase()).join();
  }

  AppUser copyWith({String? fullName, UserRole? role}) => AppUser(
    id: id,
    email: email,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.fullName == fullName &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, email, fullName, role);
}
