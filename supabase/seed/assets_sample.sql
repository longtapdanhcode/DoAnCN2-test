-- Danh mục mẫu: các bề mặt cần đánh giá trong 2 tòa nhà của một trường học,
-- dùng để demo và thử đồng bộ. Mã (code) là nội dung in trên thẻ QR 10×10 cm
-- dán ở bề mặt đó. Cột category ghi đúng tên chất liệu trong app (Tường sơn,
-- Bê tông, Gạch ốp / lát, Kim loại, Gỗ) để phiếu tự chọn chất liệu.
--
-- Chạy sau migration 20261112090000 (cần cột surface_area_m2).
-- Chạy lại an toàn: trùng mã thì cập nhật. Dữ liệu mẫu cũ (nhà máy) không bị
-- xoá tự động; xoá tay nếu không cần:
--   delete from public.assets where code in
--     ('TS-BOM-0248', 'TS-DC-0142', 'TS-TD-0086', 'TS-MK-0321', 'TS-VAN-0175');

insert into public.assets
  (code, name, category, area, location, quantity, surface_area_m2, status, updated_at)
values
  ('A-T1-A101-TT', 'Tường trái', 'Tường sơn', 'Nhà A • Tầng 1', 'Phòng A101', 1, 21.6, 'good', now()),
  ('A-T1-A101-TR', 'Trần', 'Bê tông', 'Nhà A • Tầng 1', 'Phòng A101', 1, 54.0, 'good', now()),
  ('A-T1-A101-CS', 'Cửa sổ sắt', 'Kim loại', 'Nhà A • Tầng 1', 'Phòng A101', 1, 4.8, 'good', now()),
  ('A-T2-A201-TP', 'Tường phải', 'Tường sơn', 'Nhà A • Tầng 2', 'Phòng A201', 1, 21.6, 'good', now()),
  ('A-T2-A201-SN', 'Sàn', 'Gạch ốp / lát', 'Nhà A • Tầng 2', 'Phòng A201', 1, 54.0, 'good', now()),
  ('A-T2-HL-LC', 'Lan can hành lang', 'Kim loại', 'Nhà A • Tầng 2', 'Hành lang tầng 2', 1, 12.0, 'good', now()),
  ('B-T1-WC-TT', 'Tường nhà vệ sinh', 'Gạch ốp / lát', 'Nhà B • Tầng 1', 'Nhà vệ sinh nam', 1, 18.0, 'good', now()),
  ('B-T3-B302-TR', 'Trần', 'Bê tông', 'Nhà B • Tầng 3', 'Phòng B302', 1, 48.0, 'good', now()),
  ('B-T3-B302-CR', 'Cửa ra vào', 'Gỗ', 'Nhà B • Tầng 3', 'Phòng B302', 1, 2.2, 'good', now())
on conflict (code) do update set
  name = excluded.name,
  category = excluded.category,
  area = excluded.area,
  location = excluded.location,
  quantity = excluded.quantity,
  surface_area_m2 = excluded.surface_area_m2,
  status = excluded.status,
  updated_at = excluded.updated_at;
