/// Tình trạng thực tế của thiết bị ghi nhận trong phiếu kiểm kê.
///
/// [code] là giá trị lưu trong Isar và cột `condition` trên Supabase.
enum AuditCondition {
  good('good', 'Hoạt động tốt'),
  check('check', 'Cần kiểm tra'),
  damaged('damaged', 'Hư hỏng');

  const AuditCondition(this.code, this.label);

  final String code;
  final String label;

  /// Tìm tình trạng theo mã đã lưu; trả về `null` nếu không khớp.
  static AuditCondition? fromCode(String? code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}
