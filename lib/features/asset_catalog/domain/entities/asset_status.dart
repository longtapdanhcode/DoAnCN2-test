/// Tình trạng hiện tại của một tài sản trong danh mục.
///
/// [code] là giá trị lưu trong Isar và cột `status` trên Supabase.
enum AssetStatus {
  good('good', 'Hoạt động tốt'),
  check('check', 'Cần kiểm tra'),
  damaged('damaged', 'Hư hỏng'),
  retired('retired', 'Ngừng sử dụng');

  const AssetStatus(this.code, this.label);

  final String code;
  final String label;

  /// Tìm tình trạng theo mã đã lưu; mã lạ được coi là [good].
  static AssetStatus fromCode(String? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return good;
  }
}
