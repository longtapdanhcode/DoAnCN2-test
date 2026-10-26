-- 5 tài sản mẫu theo màn "Tài sản & thiết bị" trong Figma, dùng để demo và thử
-- đồng bộ danh mục. Chạy lại an toàn: trùng mã thì cập nhật.

insert into public.assets
  (code, name, category, area, quantity, status, last_audit_at, updated_at)
values
  ('TS-BOM-0248', 'Máy bơm ly tâm Ebara', 'Thiết bị bơm', 'Kho trung tâm', 12, 'good', '2026-10-22 09:00:00+07', now()),
  ('TS-DC-0142', 'Động cơ điện Siemens', 'Thiết bị truyền động', 'Xưởng sản xuất A', 8, 'check', '2026-10-22 09:44:00+07', now()),
  ('TS-TD-0086', 'Tủ điện phân phối', 'Thiết bị điện', 'Trạm kỹ thuật', 4, 'good', '2026-10-21 14:30:00+07', now()),
  ('TS-MK-0321', 'Máy khoan Bosch GSB', 'Dụng cụ cầm tay', 'Kho vật tư B', 24, 'good', '2026-10-21 10:15:00+07', now()),
  ('TS-VAN-0175', 'Van công nghiệp DN100', 'Van & đường ống', 'Kho trung tâm', 36, 'damaged', '2026-10-20 16:00:00+07', now())
on conflict (code) do update set
  name = excluded.name,
  category = excluded.category,
  area = excluded.area,
  quantity = excluded.quantity,
  status = excluded.status,
  last_audit_at = excluded.last_audit_at,
  updated_at = excluded.updated_at;
