import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Đọc/ghi một bản JSON trong SharedPreferences (localStorage trên web),
/// dùng thay cho tệp trong thư mục tài liệu khi chạy bản web.
class PrefsJsonStore {
  const PrefsJsonStore(this.key);

  final String key;

  Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final json = jsonDecode(raw);
    return json is Map<String, dynamic> ? json : null;
  }

  Future<void> write(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(json));
  }
}
