-- Đánh giá hư hỏng bề mặt và chi phí sửa chữa.
--
-- 1. Bảng đơn giá sửa chữa repair_cost_rates: ai đã đăng nhập cũng đọc được
--    (app tải về để tính tiền khi ngoại tuyến), chỉ admin được thêm/sửa/xoá.
-- 2. audit_records lưu kết quả đánh giá (jsonb), tổng chi phí và chỉ số hư hại.
-- 3. assets lưu diện tích bề mặt (m²).
--
-- Cần chạy sau 20261030090000_auth_profiles_and_rls (dùng bảng profiles).
-- Chạy lại vẫn an toàn. Giá mẫu nằm riêng ở supabase/seed/repair_cost_rates_sample.sql.

-- 1. Bảng đơn giá -------------------------------------------------------------

create table if not exists public.repair_cost_rates (
  id uuid primary key default gen_random_uuid(),
  -- null: áp dụng cho mọi chất liệu chưa có dòng riêng.
  material text
    check (material is null or material in
      ('painted_wall', 'concrete', 'tile', 'metal', 'wood')),
  damage_type text not null
    check (damage_type in ('vet_nut', 'tham_moc', 'bong_son', 'gi_set')),
  severity text not null check (severity in ('light', 'moderate', 'severe')),
  -- Vết nứt tính theo mét dài, các loại khác theo m².
  unit text not null check (unit in ('m2', 'm')),
  unit_price numeric(14, 0) not null check (unit_price >= 0),
  method text not null default '',
  -- true: giá minh hoạ, chưa phải giá thật của nhà trường.
  is_sample boolean not null default false,
  updated_at timestamptz not null default now(),
  constraint repair_cost_rates_unit_matches_type check (
    (damage_type = 'vet_nut' and unit = 'm')
    or (damage_type <> 'vet_nut' and unit = 'm2')
  ),
  constraint repair_cost_rates_unique
    unique nulls not distinct (material, damage_type, severity)
);

-- Tài khoản hiện tại có phải admin không (dùng trong policy).
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

alter table public.repair_cost_rates enable row level security;

drop policy if exists "Đã đăng nhập: đọc đơn giá" on public.repair_cost_rates;
create policy "Đã đăng nhập: đọc đơn giá" on public.repair_cost_rates
  for select to authenticated using (true);

drop policy if exists "Admin: thêm đơn giá" on public.repair_cost_rates;
create policy "Admin: thêm đơn giá" on public.repair_cost_rates
  for insert to authenticated with check ((select public.is_admin()));

drop policy if exists "Admin: sửa đơn giá" on public.repair_cost_rates;
create policy "Admin: sửa đơn giá" on public.repair_cost_rates
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

drop policy if exists "Admin: xoá đơn giá" on public.repair_cost_rates;
create policy "Admin: xoá đơn giá" on public.repair_cost_rates
  for delete to authenticated using ((select public.is_admin()));

-- 2. Kết quả đánh giá trên phiếu kiểm kê --------------------------------------

alter table public.audit_records
  add column if not exists damage_assessment jsonb,
  add column if not exists estimated_cost numeric(14, 0)
    check (estimated_cost is null or estimated_cost >= 0),
  add column if not exists damage_index numeric(5, 2)
    check (damage_index is null or damage_index between 0 and 100);

-- 3. Diện tích bề mặt trên danh mục ------------------------------------------

alter table public.assets
  add column if not exists surface_area_m2 numeric(10, 2)
    check (surface_area_m2 is null or surface_area_m2 > 0);
