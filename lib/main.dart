import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/local_db_init.dart';
import 'core/network/supabase_config.dart';
import 'core/router/app_router.dart';

/// Entry point cho ứng dụng Field Inventory & Edge AI.
///
/// Lưu ý khi test camera trên thiết bị iOS vật lý:
/// - Impeller backend trên iOS đôi khi gây hiện tượng màn hình camera bị đen (black screen với PlatformView/Texture).
/// - Dự án đã cấu hình tắt Impeller mặc định trong `ios/Runner/Info.plist` (`<key>FLTEnableImpeller</key><false/>`).
/// - Khi chạy qua Flutter CLI, bạn cũng có thể chủ động truyền cờ:
///     `flutter run --no-enable-impeller`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[Main] Initializing Field Inventory Edge AI app...');
  }

  // Khởi tạo Supabase client (Cloud Sync & Auth).
  await initSupabase();

  // Khởi tạo Isar local database (Offline-First).
  final isar = await initIsar();
  if (kDebugMode) {
    debugPrint('[Main] Isar database ready.');
  }

  runApp(
    ProviderScope(
      overrides: [
        isarInstanceProvider.overrideWithValue(isar),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Field Inventory & Edge AI',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
