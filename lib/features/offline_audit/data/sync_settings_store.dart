import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:field_inventory_edge_ai/core/platform/prefs_json_store.dart';

/// Thiết lập đồng bộ người dùng chọn ở màn Đồng bộ.
@immutable
class SyncSettings {
  const SyncSettings({this.autoSync = true, this.wifiOnlyPhotos = false});

  /// Tự gửi phiếu lên đám mây khi có mạng, không cần bấm "Đồng bộ ngay".
  final bool autoSync;

  /// Khi tự đồng bộ trên mạng di động, phiếu có ảnh minh chứng chờ tới khi có Wi-Fi.
  final bool wifiOnlyPhotos;

  SyncSettings copyWith({bool? autoSync, bool? wifiOnlyPhotos}) => SyncSettings(
    autoSync: autoSync ?? this.autoSync,
    wifiOnlyPhotos: wifiOnlyPhotos ?? this.wifiOnlyPhotos,
  );

  Map<String, dynamic> toJson() => {
    'auto_sync': autoSync,
    'wifi_only_photos': wifiOnlyPhotos,
  };

  factory SyncSettings.fromJson(Map<String, dynamic> json) => SyncSettings(
    autoSync: json['auto_sync'] as bool? ?? true,
    wifiOnlyPhotos: json['wifi_only_photos'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncSettings &&
      other.autoSync == autoSync &&
      other.wifiOnlyPhotos == wifiOnlyPhotos;

  @override
  int get hashCode => Object.hash(autoSync, wifiOnlyPhotos);
}

/// Nơi lưu [SyncSettings] trên máy để giữ lựa chọn qua các lần mở app.
abstract class SyncSettingsStore {
  Future<SyncSettings> load();
  Future<void> save(SyncSettings settings);
}

/// Lưu thiết lập dạng JSON trong thư mục tài liệu của app.
class FileSyncSettingsStore implements SyncSettingsStore {
  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/sync_settings.json');
  }

  @override
  Future<SyncSettings> load() async {
    final file = await _file();
    if (!await file.exists()) return const SyncSettings();
    final json = jsonDecode(await file.readAsString());
    return json is Map<String, dynamic>
        ? SyncSettings.fromJson(json)
        : const SyncSettings();
  }

  @override
  Future<void> save(SyncSettings settings) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }
}

/// Bản web: lưu trong localStorage của trình duyệt.
class PrefsSyncSettingsStore implements SyncSettingsStore {
  static const _store = PrefsJsonStore('sync_settings');

  @override
  Future<SyncSettings> load() async {
    final json = await _store.read();
    return json == null ? const SyncSettings() : SyncSettings.fromJson(json);
  }

  @override
  Future<void> save(SyncSettings settings) => _store.write(settings.toJson());
}

final syncSettingsStoreProvider = Provider<SyncSettingsStore>(
  (ref) => kIsWeb ? PrefsSyncSettingsStore() : FileSyncSettingsStore(),
);
