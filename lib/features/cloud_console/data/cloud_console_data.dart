import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/data/models/asset_model.dart';
import 'package:field_inventory_edge_ai/features/asset_catalog/domain/repositories/asset_catalog_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/evidence_photo_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/cloud_audit_record_model.dart';

/// Nguồn phiếu kiểm kê trên máy chủ cho bản web (Card 28).
abstract class CloudAuditSource {
  Future<List<Map<String, dynamic>>> fetchAll();
}

class SupabaseCloudAuditSource implements CloudAuditSource {
  const SupabaseCloudAuditSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _client
        .from('audit_records')
        .select()
        .order('timestamp', ascending: false)
        .limit(2000);
    return List<Map<String, dynamic>>.from(rows);
  }
}

/// Đổi các dòng `audit_records` sang [AuditRecordModel] để dùng chung các
/// màn Tổng quan, Báo cáo, PDF với app điện thoại.
///
/// Phiếu trên đám mây luôn là phiếu đã ký (bản nháp không đồng bộ), nên có
/// [AuditRecordModel.signatureUrl] thay cho byte chữ ký, và ảnh minh chứng
/// là đường dẫn (đọc bằng [UrlEvidencePhotoStore]). Mã số phiếu đánh theo
/// thứ tự thời gian, cũ nhất là 1.
List<AuditRecordModel> cloudRowsToRecords(List<Map<String, dynamic>> rows) {
  final cloud = rows.map(CloudAuditRecordModel.fromJson).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final records = [
    for (var i = 0; i < cloud.length; i++)
      () {
        final c = cloud[i];
        return AuditRecordModel(i + 1)
          ..scanCode = c.scanCode
          ..aiDetectedLabel = c.aiDetectedLabel
          ..assetName = c.assetName
          ..quantity = c.quantity
          ..area = c.area
          ..location = c.location
          ..condition = c.condition
          ..notes = c.notes
          ..signerName = c.signerName
          ..signerRole = c.signerRole
          // Phiếu cũ trước khi lưu đường dẫn chữ ký vẫn là phiếu đã ký.
          ..signatureUrl = (c.signatureUrl?.isNotEmpty ?? false)
              ? c.signatureUrl
              : 'cloud:${c.id}'
          ..photoFiles = c.photoUrls.isEmpty ? null : c.photoUrls
          ..timestamp = DateTime.tryParse(c.timestamp)?.toLocal()
          ..isSynced = true;
      }(),
  ];
  return records.reversed.toList();
}

/// Ảnh minh chứng / chữ ký của bản web: tên ảnh là đường dẫn công khai trên
/// Supabase Storage, tải về khi cần (PDF, xem phiếu) và giữ trong bộ nhớ.
class UrlEvidencePhotoStore extends EvidencePhotoStore {
  UrlEvidencePhotoStore({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final _cache = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String name) async {
    if (!name.startsWith('http')) return null;
    final cached = _cache[name];
    if (cached != null) return cached;
    try {
      final res = await _client.get(Uri.parse(name));
      if (res.statusCode != 200) return null;
      return _cache[name] = res.bodyBytes;
    } catch (e) {
      debugPrint('[Console] Không tải được ảnh $name: $e');
      return null;
    }
  }

  @override
  Future<String> save(Uint8List bytes) =>
      throw UnsupportedError('Bản web không chụp ảnh minh chứng.');

  @override
  Future<void> delete(String name) async {}
}

/// Danh mục tài sản của bản web: đọc/ghi thẳng bảng `assets` trên Supabase,
/// không lưu ngoại tuyến và không có xung đột phiên bản.
class CloudAssetCatalogRepository implements AssetCatalogRepository {
  CloudAssetCatalogRepository(this._remote);

  final AssetRemoteDataSource _remote;
  final _changes = StreamController<List<AssetModel>>.broadcast();
  List<AssetModel>? _cache;

  Future<List<AssetModel>> _reload() async {
    final rows = await _remote.fetchAll();
    final assets = [for (final r in rows) AssetModel.fromJson(r)]
      ..sort((a, b) => a.code.compareTo(b.code));
    _cache = assets;
    _changes.add(assets);
    return assets;
  }

  @override
  Stream<List<AssetModel>> watchAll() async* {
    yield _cache ?? await _reload();
    yield* _changes.stream;
  }

  @override
  Future<AssetModel?> findByCode(String code) async {
    final assets = _cache ?? await _reload();
    for (final a in assets) {
      if (a.code == code) return a;
    }
    return null;
  }

  @override
  Future<void> save(AssetModel asset) async {
    asset
      ..updatedAt = DateTime.now()
      ..isSynced = true;
    await _remote.upsert([asset.toJson()]);
    await _reload();
  }

  @override
  Future<CatalogSyncResult> sync() async {
    final assets = await _reload();
    return CatalogSyncResult(pushed: 0, pulled: assets.length);
  }

  @override
  Future<void> resolveConflict(
    String code,
    Set<String> useRemoteFields,
  ) async {}
}
