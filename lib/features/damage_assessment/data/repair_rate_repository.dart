import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:field_inventory_edge_ai/core/network/supabase_provider.dart';
import 'package:field_inventory_edge_ai/core/platform/prefs_json_store.dart';

import '../domain/damage_calculator.dart';
import '../domain/entities/repair_rate.dart';
import 'sample_repair_rates.dart';

/// Nguồn bảng đơn giá trên máy chủ.
abstract class RepairRateRemoteSource {
  Future<List<Map<String, dynamic>>> fetchRows();
}

class SupabaseRepairRateRemoteSource implements RepairRateRemoteSource {
  /// Lấy client lúc gọi, để app chưa cấu hình Supabase vẫn dùng được giá đã
  /// lưu hoặc giá mẫu thay vì lỗi ngay khi tạo provider.
  const SupabaseRepairRateRemoteSource(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<List<Map<String, dynamic>>> fetchRows() async {
    final rows = await _client().from('repair_cost_rates').select();
    return List<Map<String, dynamic>>.from(rows);
  }
}

/// Nơi lưu bản đơn giá gần nhất trên máy, để tính tiền khi ngoại tuyến.
abstract class RepairRateCacheStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> json);
}

/// Lưu dạng JSON trong thư mục tài liệu của app.
class FileRepairRateCacheStore implements RepairRateCacheStore {
  Future<File> _file() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/repair_cost_rates.json');
  }

  @override
  Future<Map<String, dynamic>?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString());
    return json is Map<String, dynamic> ? json : null;
  }

  @override
  Future<void> write(Map<String, dynamic> json) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(json), flush: true);
  }
}

/// Bản web: lưu trong localStorage.
class PrefsRepairRateCacheStore implements RepairRateCacheStore {
  static const _store = PrefsJsonStore('repair_cost_rates');

  @override
  Future<Map<String, dynamic>?> read() => _store.read();

  @override
  Future<void> write(Map<String, dynamic> json) => _store.write(json);
}

/// Tải bảng đơn giá theo thứ tự: máy chủ → bản đã lưu trên máy → giá mẫu.
class RepairRateRepository {
  const RepairRateRepository(
    this._remote,
    this._cache, {
    this.timeout = const Duration(seconds: 10),
    this.now = DateTime.now,
  });

  final RepairRateRemoteSource _remote;
  final RepairRateCacheStore _cache;
  final Duration timeout;

  /// Đồng hồ ghi thời điểm tải; test thay bằng giờ cố định.
  final DateTime Function() now;

  Future<RepairRateTable> load() async {
    try {
      final rows = await _remote.fetchRows().timeout(timeout);
      final rates = [for (final r in rows) ?RepairRate.fromJson(r)];
      // Bảng trên máy chủ chưa có giá nào: dùng bản cũ hoặc giá mẫu, và
      // không ghi đè bản đã lưu.
      if (rates.isNotEmpty) {
        final fetchedAt = now();
        try {
          await _cache.write({
            'fetched_at': fetchedAt.toUtc().toIso8601String(),
            'rates': [for (final r in rates) r.toJson()],
          });
        } catch (e) {
          debugPrint('[RepairRates] Không lưu được bảng giá: $e');
        }
        return RepairRateTable(
          List.unmodifiable(rates),
          source: RepairRateSource.remote,
          fetchedAt: fetchedAt,
        );
      }
    } catch (e) {
      debugPrint('[RepairRates] Không tải được bảng giá từ máy chủ: $e');
    }

    final cached = await _readCache();
    if (cached != null) return cached;
    return const RepairRateTable(
      sampleRepairRates,
      source: RepairRateSource.sample,
    );
  }

  Future<RepairRateTable?> _readCache() async {
    try {
      final json = await _cache.read();
      if (json == null) return null;
      final rates = [
        for (final r in (json['rates'] as List?) ?? const [])
          if (r is Map<String, dynamic>) ?RepairRate.fromJson(r),
      ];
      if (rates.isEmpty) return null;
      final at = json['fetched_at'];
      return RepairRateTable(
        List.unmodifiable(rates),
        source: RepairRateSource.cache,
        fetchedAt: at is String ? DateTime.tryParse(at)?.toLocal() : null,
      );
    } catch (e) {
      debugPrint('[RepairRates] Bản giá đã lưu bị hỏng: $e');
      return null;
    }
  }
}

final repairRateRemoteSourceProvider = Provider<RepairRateRemoteSource>(
  (ref) =>
      SupabaseRepairRateRemoteSource(() => ref.read(supabaseClientProvider)),
);

final repairRateCacheStoreProvider = Provider<RepairRateCacheStore>(
  (ref) => kIsWeb ? PrefsRepairRateCacheStore() : FileRepairRateCacheStore(),
);

final repairRateRepositoryProvider = Provider<RepairRateRepository>(
  (ref) => RepairRateRepository(
    ref.watch(repairRateRemoteSourceProvider),
    ref.watch(repairRateCacheStoreProvider),
  ),
);

/// Bảng đơn giá đang dùng. Gọi `ref.invalidate(repairRateTableProvider)` để
/// tải lại (ví dụ khi có mạng trở lại hoặc admin vừa sửa giá).
final repairRateTableProvider = FutureProvider<RepairRateTable>(
  (ref) => ref.watch(repairRateRepositoryProvider).load(),
);

/// Bộ tính dùng bảng đơn giá hiện tại.
final damageCalculatorProvider = FutureProvider<DamageCalculator>(
  (ref) async =>
      DamageCalculator(await ref.watch(repairRateTableProvider.future)),
);
