import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:field_inventory_edge_ai/features/offline_audit/data/evidence_photo_store.dart';

/// Kho ảnh minh chứng trong bộ nhớ, dùng cho test (không cần hệ tệp thật).
class MemoryEvidencePhotoStore extends EvidencePhotoStore {
  final Map<String, Uint8List> files = {};
  int _counter = 0;

  @override
  Future<String> save(Uint8List bytes) async {
    final name = 'ev_test_${_counter++}.jpg';
    files[name] = bytes;
    return name;
  }

  @override
  Future<Uint8List?> read(String name) async => files[name];

  @override
  Future<void> delete(String name) async => files.remove(name);
}

/// Bộ chọn ảnh giả: trả về ảnh có sẵn hoặc `null` (người dùng huỷ).
class FakeEvidencePhotoPicker implements EvidencePhotoPicker {
  FakeEvidencePhotoPicker(this.result);

  Uint8List? result;
  final List<EvidencePhotoSource> requested = [];

  @override
  Future<Uint8List?> pick(EvidencePhotoSource source) async {
    requested.add(source);
    return result;
  }
}

/// Ảnh JPEG nhỏ hợp lệ để dùng trong test.
Uint8List sampleJpeg({int size = 64}) {
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(30, 140, 120));
  return Uint8List.fromList(img.encodeJpg(image));
}
