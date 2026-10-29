import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_inventory_edge_ai/core/network/connectivity_provider.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/controllers/asset_catalog_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/sync_settings_store.dart';

import 'audit_records_provider.dart';
import 'sync_controller.dart';

/// Thiết lập đồng bộ đang dùng, đọc từ máy khi mở app và lưu lại mỗi khi đổi.
class SyncSettingsNotifier extends AsyncNotifier<SyncSettings> {
  @override
  Future<SyncSettings> build() async {
    try {
      return await ref.read(syncSettingsStoreProvider).load();
    } catch (e) {
      debugPrint('[AutoSync] Không đọc được thiết lập đồng bộ: $e');
      return const SyncSettings();
    }
  }

  Future<void> setAutoSync(bool value) =>
      _update((s) => s.copyWith(autoSync: value));

  Future<void> setWifiOnlyPhotos(bool value) =>
      _update((s) => s.copyWith(wifiOnlyPhotos: value));

  Future<void> _update(SyncSettings Function(SyncSettings) change) async {
    final next = change(state.value ?? const SyncSettings());
    state = AsyncData(next);
    try {
      await ref.read(syncSettingsStoreProvider).save(next);
    } catch (e) {
      debugPrint('[AutoSync] Không lưu được thiết lập đồng bộ: $e');
    }
  }
}

final syncSettingsProvider =
    AsyncNotifierProvider<SyncSettingsNotifier, SyncSettings>(
      SyncSettingsNotifier.new,
    );

/// Kết quả lần tự đồng bộ gần nhất, hiển thị ở màn Đồng bộ.
@immutable
class AutoSyncStatus {
  const AutoSyncStatus({
    this.lastSyncedAt,
    this.lastCount = 0,
    this.failures = 0,
    this.nextRetryAt,
    this.waitingForWifi = 0,
  });

  /// Lần tự đồng bộ thành công gần nhất.
  final DateTime? lastSyncedAt;

  /// Số phiếu gửi lên ở lần thành công gần nhất.
  final int lastCount;

  /// Số lần lỗi liên tiếp (0 khi lần gần nhất thành công).
  final int failures;

  /// Thời điểm sẽ thử lại sau lỗi.
  final DateTime? nextRetryAt;

  /// Số phiếu có ảnh đang chờ Wi-Fi.
  final int waitingForWifi;
}

class AutoSyncStatusNotifier extends Notifier<AutoSyncStatus> {
  @override
  AutoSyncStatus build() => const AutoSyncStatus();

  void set(AutoSyncStatus status) => state = status;
}

/// Trạng thái tự đồng bộ. Tách khỏi [autoSyncProvider] để màn hình chỉ đọc
/// trạng thái mà không tự khởi động bộ đồng bộ (bộ này do khung app giữ).
final autoSyncStatusProvider =
    NotifierProvider<AutoSyncStatusNotifier, AutoSyncStatus>(
      AutoSyncStatusNotifier.new,
    );

/// Các khoảng chờ của bộ tự đồng bộ (test thay bằng giá trị nhỏ).
@immutable
class AutoSyncTimings {
  const AutoSyncTimings({
    this.debounce = const Duration(seconds: 3),
    this.retryBase = const Duration(seconds: 30),
    this.retryMax = const Duration(minutes: 5),
  });

  /// Chờ sau mỗi sự kiện để gộp nhiều thay đổi liền nhau thành một lần gửi.
  final Duration debounce;

  /// Lần thử lại đầu tiên sau lỗi; nhân đôi sau mỗi lỗi tiếp theo.
  final Duration retryBase;

  /// Khoảng chờ thử lại dài nhất.
  final Duration retryMax;

  Duration retryAfter(int failures) {
    final ms = retryBase.inMilliseconds * pow(2, max(0, failures - 1));
    return Duration(milliseconds: min(ms.toInt(), retryMax.inMilliseconds));
  }
}

final autoSyncTimingsProvider = Provider<AutoSyncTimings>(
  (ref) => const AutoSyncTimings(),
);

/// Bộ tự đồng bộ (Card 24): gửi các phiếu đã ký lên Supabase mà không cần
/// bấm "Đồng bộ ngay".
///
/// Chạy khi: mở app, có mạng trở lại, chuyển sang Wi-Fi, app quay lại từ nền,
/// có phiếu mới ký, hoặc vừa bật tuỳ chọn. Lỗi thì thử lại với khoảng chờ tăng
/// dần (30 giây, 1, 2, 4 rồi tối đa 5 phút) khi vẫn còn mạng. Chỉ chạy khi app
/// đang mở: iOS không cho app chạy đồng bộ tuỳ ý lúc đã đóng.
class AutoSyncController extends Notifier<void> {
  Timer? _timer;
  int _failures = 0;

  @override
  void build() {
    ref.listen(isOnlineProvider, (prev, next) {
      if (next.value == true && prev?.value != true) schedule();
    });
    ref.listen(isOnWifiProvider, (prev, next) {
      if (next.value == true && prev?.value != true) schedule();
    });
    ref.listen(pendingSyncCountProvider, (prev, next) {
      if (next > (prev ?? 0)) schedule();
    }, fireImmediately: true);
    ref.listen(syncSettingsProvider, (prev, next) {
      final before = prev?.value;
      final now = next.value;
      if (now == null) return;
      if (before == null ||
          (now.autoSync && !before.autoSync) ||
          (!now.wifiOnlyPhotos && before.wifiOnlyPhotos)) {
        schedule();
      }
    });

    final lifecycle = AppLifecycleListener(onResume: schedule);
    ref.onDispose(() {
      _timer?.cancel();
      lifecycle.dispose();
    });
  }

  /// Hẹn một lần đồng bộ sau khoảng [delay] (mặc định: khoảng gộp sự kiện).
  void schedule([Duration? delay]) {
    if (!ref.mounted) return;
    // Sự kiện mới (có mạng, phiếu mới...) thay cho lịch thử lại đang chờ.
    if (delay == null) _failures = 0;
    _timer?.cancel();
    _timer = Timer(delay ?? ref.read(autoSyncTimingsProvider).debounce, _run);
  }

  Future<void> _run() async {
    if (!ref.mounted) return;
    final settings = ref.read(syncSettingsProvider).value;
    if (settings == null || !settings.autoSync) return;
    if (ref.read(isOnlineProvider).value != true) return;
    if (ref.read(pendingSyncCountProvider) == 0) return;

    final timings = ref.read(autoSyncTimingsProvider);
    // Đang có lượt đồng bộ khác (người dùng bấm tay): hẹn lại sau.
    if (ref.read(syncControllerProvider).isLoading) {
      schedule(timings.debounce);
      return;
    }

    final skipPhotos =
        settings.wifiOnlyPhotos && ref.read(isOnWifiProvider).value != true;
    final status = ref.read(autoSyncStatusProvider.notifier);
    try {
      final count = await ref
          .read(syncControllerProvider.notifier)
          .syncAll(skipRecordsWithPhotos: skipPhotos);
      if (!ref.mounted) return;

      // Danh mục tài sản đi kèm như khi bấm tay; lỗi danh mục không tính là
      // lỗi đồng bộ phiếu.
      try {
        await ref.read(assetCatalogRepositoryProvider).sync();
      } catch (e) {
        debugPrint('[AutoSync] Lỗi đồng bộ danh mục tài sản: $e');
      }
      if (!ref.mounted) return;

      _failures = 0;
      final records = await ref
          .read(isarAuditRepositoryProvider)
          .getAllRecords();
      if (!ref.mounted) return;
      status.set(
        AutoSyncStatus(
          lastSyncedAt: count > 0
              ? DateTime.now()
              : ref.read(autoSyncStatusProvider).lastSyncedAt,
          lastCount: count > 0
              ? count
              : ref.read(autoSyncStatusProvider).lastCount,
          waitingForWifi: skipPhotos
              ? records
                    .where((r) => !r.isSynced && !r.isDraft && r.hasPhotos)
                    .length
              : 0,
        ),
      );
    } catch (e) {
      debugPrint('[AutoSync] Lỗi tự đồng bộ, sẽ thử lại: $e');
      if (!ref.mounted) return;
      _failures++;
      final wait = timings.retryAfter(_failures);
      final previous = ref.read(autoSyncStatusProvider);
      status.set(
        AutoSyncStatus(
          lastSyncedAt: previous.lastSyncedAt,
          lastCount: previous.lastCount,
          failures: _failures,
          nextRetryAt: DateTime.now().add(wait),
        ),
      );
      if (ref.read(isOnlineProvider).value == true) schedule(wait);
    }
  }
}

/// Giữ sống suốt vòng đời app; khung app (FieldlineShell) theo dõi để khởi động.
final autoSyncProvider = NotifierProvider<AutoSyncController, void>(
  AutoSyncController.new,
);
