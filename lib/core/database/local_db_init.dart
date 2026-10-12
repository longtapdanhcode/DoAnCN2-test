import 'package:flutter/foundation.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

part 'local_db_init.g.dart';

/// Khởi tạo Isar database toàn cục.
///
/// Hàm này lấy đường dẫn thư mục documents của thiết bị,
/// sau đó mở Isar database với tất cả các schema cần thiết.
///
/// Gọi hàm này **một lần duy nhất** trong `main()` trước khi runApp.
Future<Isar> initIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = Isar.open(
    schemas: [AuditRecordModelSchema],
    directory: dir.path,
  );

  if (kDebugMode) {
    debugPrint('[Isar] Database initialized at: ${dir.path}');
  }

  return isar;
}

/// Riverpod provider toàn cục giữ instance Isar suốt vòng đời ứng dụng.
///
/// Provider này được khai báo `keepAlive: true` để đảm bảo Isar instance
/// không bao giờ bị dispose trong quá trình app chạy.
///
/// **Lưu ý**: Provider này cần được override trong `ProviderScope` ở `main.dart`
/// bằng instance thật từ `initIsar()`:
/// ```dart
/// ProviderScope(
///   overrides: [isarInstanceProvider.overrideWithValue(isar)],
///   child: MyApp(),
/// )
/// ```
@Riverpod(keepAlive: true)
Isar isarInstance(Ref ref) {
  // Giá trị mặc định – sẽ bị override trong main.dart.
  // Nếu truy cập mà chưa override sẽ throw UnimplementedError.
  throw UnimplementedError(
    'isarInstanceProvider phải được override trong ProviderScope '
    'với instance Isar thật từ initIsar().',
  );
}
