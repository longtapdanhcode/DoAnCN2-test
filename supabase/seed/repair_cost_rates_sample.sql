-- Bảng đơn giá MINH HOẠ (is_sample = true), chưa phải giá thật của nhà trường.
-- Thay bằng giá do phòng Cơ sở vật chất cung cấp trước khi dùng báo cáo thật.
-- Trùng nội dung với lib/features/damage_assessment/data/sample_repair_rates.dart.
-- Chạy sau migration 20261112090000. Chạy lại an toàn: trùng tổ hợp thì cập nhật.

insert into public.repair_cost_rates
  (material, damage_type, severity, unit, unit_price, method, is_sample)
values
  -- Vết nứt (VND / mét dài)
  (null, 'vet_nut', 'light', 'm', 80000, 'Trám vết nứt bằng keo/bột trét, sơn dặm', true),
  (null, 'vet_nut', 'moderate', 'm', 150000, 'Mở rộng rãnh, trám vữa sửa chữa, sơn lại', true),
  (null, 'vet_nut', 'severe', 'm', 350000, 'Bơm keo epoxy, gia cố, trát và sơn lại', true),
  -- Thấm nước / ẩm mốc (VND / m²)
  (null, 'tham_moc', 'light', 'm2', 120000, 'Xử lý mốc, sơn chống thấm', true),
  (null, 'tham_moc', 'moderate', 'm2', 220000, 'Cạo lớp sơn, chống thấm, bả và sơn lại', true),
  (null, 'tham_moc', 'severe', 'm2', 380000, 'Đục lớp trát, chống thấm, trát và sơn lại', true),
  -- Bong tróc sơn (VND / m²)
  (null, 'bong_son', 'light', 'm2', 60000, 'Cạo chỗ bong, sơn dặm', true),
  (null, 'bong_son', 'moderate', 'm2', 90000, 'Cạo, bả matit, sơn lại', true),
  (null, 'bong_son', 'severe', 'm2', 150000, 'Cạo toàn bộ, bả matit, sơn lót và sơn phủ', true),
  -- Gỉ sét (VND / m²)
  (null, 'gi_set', 'light', 'm2', 90000, 'Đánh gỉ, sơn chống gỉ', true),
  (null, 'gi_set', 'moderate', 'm2', 160000, 'Đánh gỉ, sơn chống gỉ và sơn phủ', true),
  (null, 'gi_set', 'severe', 'm2', 450000, 'Cắt, hàn thay phần mục, sơn chống gỉ và sơn phủ', true)
on conflict (material, damage_type, severity) do update set
  unit = excluded.unit,
  unit_price = excluded.unit_price,
  method = excluded.method,
  is_sample = excluded.is_sample,
  updated_at = now();
