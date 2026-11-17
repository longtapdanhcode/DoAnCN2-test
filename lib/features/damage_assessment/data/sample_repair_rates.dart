import '../domain/entities/damage_enums.dart';
import '../domain/entities/repair_rate.dart';

/// Bảng đơn giá MINH HOẠ, dùng khi app chưa từng tải được bảng giá từ
/// Supabase. Không phải giá thật của nhà trường: phải thay bằng bảng giá do
/// phòng Cơ sở vật chất cung cấp (màn quản lý đơn giá trên bản web).
///
/// Trùng nội dung với `supabase/seed/repair_cost_rates_sample.sql`.
const List<RepairRate> sampleRepairRates = [
  // Vết nứt (VND / mét dài)
  RepairRate(
    damageType: DamageType.crack,
    severity: DamageSeverity.light,
    unitPrice: 80000,
    method: 'Trám vết nứt bằng keo/bột trét, sơn dặm',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.crack,
    severity: DamageSeverity.moderate,
    unitPrice: 150000,
    method: 'Mở rộng rãnh, trám vữa sửa chữa, sơn lại',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.crack,
    severity: DamageSeverity.severe,
    unitPrice: 350000,
    method: 'Bơm keo epoxy, gia cố, trát và sơn lại',
    isSample: true,
  ),
  // Thấm nước / ẩm mốc (VND / m²)
  RepairRate(
    damageType: DamageType.waterMold,
    severity: DamageSeverity.light,
    unitPrice: 120000,
    method: 'Xử lý mốc, sơn chống thấm',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.waterMold,
    severity: DamageSeverity.moderate,
    unitPrice: 220000,
    method: 'Cạo lớp sơn, chống thấm, bả và sơn lại',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.waterMold,
    severity: DamageSeverity.severe,
    unitPrice: 380000,
    method: 'Đục lớp trát, chống thấm, trát và sơn lại',
    isSample: true,
  ),
  // Bong tróc sơn (VND / m²)
  RepairRate(
    damageType: DamageType.peelingPaint,
    severity: DamageSeverity.light,
    unitPrice: 60000,
    method: 'Cạo chỗ bong, sơn dặm',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.peelingPaint,
    severity: DamageSeverity.moderate,
    unitPrice: 90000,
    method: 'Cạo, bả matit, sơn lại',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.peelingPaint,
    severity: DamageSeverity.severe,
    unitPrice: 150000,
    method: 'Cạo toàn bộ, bả matit, sơn lót và sơn phủ',
    isSample: true,
  ),
  // Gỉ sét (VND / m²)
  RepairRate(
    damageType: DamageType.rust,
    severity: DamageSeverity.light,
    unitPrice: 90000,
    method: 'Đánh gỉ, sơn chống gỉ',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.rust,
    severity: DamageSeverity.moderate,
    unitPrice: 160000,
    method: 'Đánh gỉ, sơn chống gỉ và sơn phủ',
    isSample: true,
  ),
  RepairRate(
    damageType: DamageType.rust,
    severity: DamageSeverity.severe,
    unitPrice: 450000,
    method: 'Cắt, hàn thay phần mục, sơn chống gỉ và sơn phủ',
    isSample: true,
  ),
];
