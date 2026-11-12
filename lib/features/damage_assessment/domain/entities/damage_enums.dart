/// Đơn vị đo khối lượng hư hỏng.
enum MeasureUnit {
  squareMeter('m2', 'm²'),
  meter('m', 'm');

  const MeasureUnit(this.code, this.symbol);

  /// Giá trị lưu trong Isar và cột `unit` trên Supabase.
  final String code;

  /// Ký hiệu hiển thị.
  final String symbol;

  static MeasureUnit? fromCode(String? code) {
    for (final u in values) {
      if (u.code == code) return u;
    }
    return null;
  }
}

/// Bốn loại hư hỏng bề mặt mà model AI phân vùng.
///
/// Thứ tự khai báo trùng thứ tự lớp lúc train (xem
/// `docs/ai-training/HUONG_DAN_TRAIN_MODEL_BE_MAT.md`), nên [index] chính là
/// chỉ số lớp của model.
enum DamageType {
  crack('vet_nut', 'Vết nứt', MeasureUnit.meter),
  waterMold('tham_moc', 'Thấm nước / ẩm mốc', MeasureUnit.squareMeter),
  peelingPaint('bong_son', 'Bong tróc sơn', MeasureUnit.squareMeter),
  rust('gi_set', 'Gỉ sét', MeasureUnit.squareMeter);

  const DamageType(this.code, this.label, this.unit);

  /// Tên lớp của model, cũng là giá trị lưu trữ.
  final String code;
  final String label;

  /// Vết nứt đo theo chiều dài, các loại còn lại đo theo diện tích.
  final MeasureUnit unit;

  static DamageType? fromCode(String? code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

/// Mức độ hư hỏng, suy ra từ chỉ số hư hại.
enum DamageSeverity {
  light('light', 'Nhẹ'),
  moderate('moderate', 'Vừa'),
  severe('severe', 'Nặng');

  const DamageSeverity(this.code, this.label);

  final String code;
  final String label;

  static DamageSeverity? fromCode(String? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// Chất liệu bề mặt, quyết định đơn giá sửa chữa.
enum SurfaceMaterial {
  paintedWall('painted_wall', 'Tường sơn'),
  concrete('concrete', 'Bê tông'),
  tile('tile', 'Gạch ốp / lát'),
  metal('metal', 'Kim loại'),
  wood('wood', 'Gỗ');

  const SurfaceMaterial(this.code, this.label);

  final String code;
  final String label;

  static SurfaceMaterial? fromCode(String? code) {
    for (final m in values) {
      if (m.code == code) return m;
    }
    return null;
  }
}

/// Nguồn của một số đo hư hỏng.
enum MeasurementSource {
  /// Do AI đo, người kiểm kê giữ nguyên.
  ai('ai'),

  /// AI đo, người kiểm kê đã sửa số.
  edited('edited'),

  /// Người kiểm kê tự thêm (chỗ AI không thấy).
  manual('manual');

  const MeasurementSource(this.code);

  final String code;

  static MeasurementSource fromCode(String? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return MeasurementSource.manual;
  }
}
