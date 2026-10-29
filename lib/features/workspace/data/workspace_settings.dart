import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:field_inventory_edge_ai/core/platform/prefs_json_store.dart';

/// Ca làm việc hiển thị ở đầu Tổng quan.
const workShifts = ['Ca sáng', 'Ca chiều', 'Ca đêm', 'Hành chính'];

/// Nơi đang kiểm kê (tên nhà máy/kho) và ca làm việc, chọn ở Cài đặt.
@immutable
class WorkspaceSettings {
  const WorkspaceSettings({
    this.siteName = 'Nhà máy Bình An',
    this.shift = 'Ca sáng',
  });

  final String siteName;
  final String shift;

  /// Dòng hiển thị dưới thương hiệu ở Tổng quan (ví dụ "Nhà máy Bình An · Ca sáng").
  String get summary => '$siteName  ·  $shift';

  WorkspaceSettings copyWith({String? siteName, String? shift}) =>
      WorkspaceSettings(
        siteName: siteName ?? this.siteName,
        shift: shift ?? this.shift,
      );

  Map<String, dynamic> toJson() => {'site_name': siteName, 'shift': shift};

  factory WorkspaceSettings.fromJson(Map<String, dynamic> json) {
    const d = WorkspaceSettings();
    final site = (json['site_name'] as String?)?.trim();
    final shift = json['shift'] as String?;
    return WorkspaceSettings(
      siteName: site == null || site.isEmpty ? d.siteName : site,
      shift: workShifts.contains(shift) ? shift! : d.shift,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorkspaceSettings &&
      other.siteName == siteName &&
      other.shift == shift;

  @override
  int get hashCode => Object.hash(siteName, shift);
}

abstract class WorkspaceSettingsStore {
  Future<WorkspaceSettings> load();
  Future<void> save(WorkspaceSettings settings);
}

/// Lưu dạng JSON trong thư mục tài liệu của app.
class FileWorkspaceSettingsStore implements WorkspaceSettingsStore {
  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/workspace_settings.json');
  }

  @override
  Future<WorkspaceSettings> load() async {
    final file = await _file();
    if (!await file.exists()) return const WorkspaceSettings();
    final json = jsonDecode(await file.readAsString());
    return json is Map<String, dynamic>
        ? WorkspaceSettings.fromJson(json)
        : const WorkspaceSettings();
  }

  @override
  Future<void> save(WorkspaceSettings settings) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }
}

/// Bản web: lưu trong localStorage của trình duyệt.
class PrefsWorkspaceSettingsStore implements WorkspaceSettingsStore {
  static const _store = PrefsJsonStore('workspace_settings');

  @override
  Future<WorkspaceSettings> load() async {
    final json = await _store.read();
    return json == null
        ? const WorkspaceSettings()
        : WorkspaceSettings.fromJson(json);
  }

  @override
  Future<void> save(WorkspaceSettings settings) =>
      _store.write(settings.toJson());
}

final workspaceSettingsStoreProvider = Provider<WorkspaceSettingsStore>(
  (ref) =>
      kIsWeb ? PrefsWorkspaceSettingsStore() : FileWorkspaceSettingsStore(),
);

class WorkspaceSettingsNotifier extends AsyncNotifier<WorkspaceSettings> {
  @override
  Future<WorkspaceSettings> build() async {
    try {
      return await ref.read(workspaceSettingsStoreProvider).load();
    } catch (e) {
      debugPrint('[Workspace] Không đọc được thiết lập: $e');
      return const WorkspaceSettings();
    }
  }

  Future<void> save(WorkspaceSettings next) async {
    state = AsyncData(next);
    try {
      await ref.read(workspaceSettingsStoreProvider).save(next);
    } catch (e) {
      debugPrint('[Workspace] Không lưu được thiết lập: $e');
    }
  }
}

final workspaceSettingsProvider =
    AsyncNotifierProvider<WorkspaceSettingsNotifier, WorkspaceSettings>(
      WorkspaceSettingsNotifier.new,
    );

/// Thiết lập hiện tại để hiển thị (mặc định khi chưa đọc xong).
final workspaceProvider = Provider<WorkspaceSettings>(
  (ref) =>
      ref.watch(workspaceSettingsProvider).value ?? const WorkspaceSettings(),
);
