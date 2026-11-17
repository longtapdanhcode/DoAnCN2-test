import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

import 'damage_format.dart';

/// Dòng "khối lượng" ngắn của một phiếu ở các danh sách: phiếu đánh giá bề
/// mặt hiện chi phí ước tính, phiếu kiểm kê thường hiện số lượng.
String auditAmountLabel(AuditRecordModel r) {
  final cost = r.estimatedCost;
  if (r.damageAssessmentJson != null && cost != null) return formatVnd(cost);
  return '${r.quantity} thiết bị';
}
