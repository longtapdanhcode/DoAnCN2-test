-- Danh mục tài sản dùng chung giữa các thiết bị kiểm kê.
-- Mã tài sản (code) là khóa chính, trùng với khóa của AssetModel trong Isar.

create table if not exists public.assets (
  code text primary key,
  name text not null,
  category text,
  area text,
  location text,
  quantity integer not null default 1 check (quantity >= 0),
  status text not null default 'good'
    check (status in ('good', 'check', 'damaged', 'retired')),
  last_audit_at timestamptz,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists assets_area_idx on public.assets (area);
create index if not exists assets_status_idx on public.assets (status);

-- Cùng mức quyền với audit_records: app dùng khóa anon được đọc, thêm, sửa;
-- không có quyền xoá.
alter table public.assets enable row level security;

create policy "Cho phép đọc assets"
  on public.assets for select
  to anon, authenticated
  using (true);

create policy "Cho phép thêm assets"
  on public.assets for insert
  to anon, authenticated
  with check (true);

create policy "Cho phép cập nhật assets"
  on public.assets for update
  to anon, authenticated
  using (true)
  with check (true);
