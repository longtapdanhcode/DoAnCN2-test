import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Số ảnh minh chứng tối đa cho mỗi phiếu kiểm kê.
const int maxEvidencePhotos = 3;

/// Nơi lưu ảnh minh chứng hiện trường trên máy (offline-first).
///
/// Phiếu chỉ giữ **tên tệp**: thư mục tài liệu của iOS đổi đường dẫn tuyệt đối
/// sau khi cập nhật app, nên đường dẫn đầy đủ được dựng lại khi cần.
abstract class EvidencePhotoStore {
  /// Lưu ảnh và trả về tên tệp.
  Future<String> save(Uint8List bytes);

  /// Đọc ảnh theo tên tệp; `null` nếu không còn.
  Future<Uint8List?> read(String name);

  /// Xoá ảnh (bỏ qua nếu không còn).
  Future<void> delete(String name);

  /// Đọc nhiều ảnh cùng lúc, bỏ qua ảnh không đọc được.
  Future<Map<String, Uint8List>> readAll(Iterable<String> names) async {
    final result = <String, Uint8List>{};
    for (final name in names) {
      final bytes = await read(name);
      if (bytes != null) result[name] = bytes;
    }
    return result;
  }
}

class FileEvidencePhotoStore extends EvidencePhotoStore {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/evidence');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Chỉ nhận tên tệp thuần (không có thư mục) để tránh đọc/xoá ngoài vùng lưu.
  static bool isSafeName(String name) =>
      name.isNotEmpty &&
      !name.contains('/') &&
      !name.contains('\\') &&
      !name.startsWith('.');

  @override
  Future<String> save(Uint8List bytes) async {
    final name =
        'ev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}.jpg';
    final dir = await _dir();
    await File('${dir.path}/$name').writeAsBytes(bytes, flush: true);
    return name;
  }

  @override
  Future<Uint8List?> read(String name) async {
    if (!isSafeName(name)) return null;
    final file = File('${(await _dir()).path}/$name');
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> delete(String name) async {
    if (!isSafeName(name)) return;
    final file = File('${(await _dir()).path}/$name');
    if (await file.exists()) await file.delete();
  }
}

final evidencePhotoStoreProvider = Provider<EvidencePhotoStore>(
  (ref) => FileEvidencePhotoStore(),
);

/// Nguồn ảnh khi thêm ảnh minh chứng.
enum EvidencePhotoSource { camera, gallery }

/// Chụp hoặc chọn một ảnh (đã nén) — tách riêng để test không cần camera.
abstract class EvidencePhotoPicker {
  /// Trả về `null` nếu người dùng huỷ.
  Future<Uint8List?> pick(EvidencePhotoSource source);
}

class ImageEvidencePhotoPicker implements EvidencePhotoPicker {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> pick(EvidencePhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == EvidencePhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Nén để phiếu và bản tải lên không quá nặng.
      maxWidth: 1600,
      imageQuality: 75,
    );
    return file?.readAsBytes();
  }
}

final evidencePhotoPickerProvider = Provider<EvidencePhotoPicker>(
  (ref) => ImageEvidencePhotoPicker(),
);
