import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/offline_audit/data/evidence_photo_store.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/cloud_audit_record_model.dart';

void main() {
  group('CloudAuditRecordModel ảnh minh chứng', () {
    AuditRecordModel record() => AuditRecordModel(1)
      ..scanCode = 'TS-1'
      ..quantity = 1
      ..timestamp = DateTime(2026, 10, 26);

    test(
      'không gửi photo_urls khi phiếu không có ảnh (tương thích bảng cũ)',
      () {
        final json = CloudAuditRecordModel.fromAuditRecordModel(record())
            .toJson();
        expect(json.containsKey('photo_urls'), isFalse);
      },
    );

    test('gửi photo_urls khi có ảnh và đọc lại được', () {
      final cloud = CloudAuditRecordModel.fromAuditRecordModel(
        record(),
        photoUrls: ['https://x/a.jpg', 'https://x/b.jpg'],
      );
      final json = cloud.toJson();
      expect(json['photo_urls'], ['https://x/a.jpg', 'https://x/b.jpg']);
      expect(CloudAuditRecordModel.fromJson(json), cloud);
    });
  });

  test('FileEvidencePhotoStore chỉ nhận tên tệp thuần', () {
    expect(FileEvidencePhotoStore.isSafeName('ev_1_2.jpg'), isTrue);
    expect(FileEvidencePhotoStore.isSafeName('../secret'), isFalse);
    expect(FileEvidencePhotoStore.isSafeName('a/b.jpg'), isFalse);
    expect(FileEvidencePhotoStore.isSafeName('.hidden'), isFalse);
    expect(FileEvidencePhotoStore.isSafeName(''), isFalse);
  });

  test('tối đa 3 ảnh mỗi phiếu', () => expect(maxEvidencePhotos, 3));
}
