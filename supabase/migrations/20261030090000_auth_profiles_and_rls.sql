-- Card 26: Đăng nhập bằng Supabase Auth.
--
-- 1. Bảng profiles (họ tên, vai trò) tạo tự động khi có tài khoản mới.
-- 2. audit_records lưu người tạo phiếu (created_by).
-- 3. Khoá dữ liệu: chỉ tài khoản đã đăng nhập mới đọc/ghi được; anon key
--    không còn quyền gì trên audit_records, assets và hai bucket ảnh.
--
-- Chạy một lần trong Supabase Dashboard -> SQL Editor. Chạy lại vẫn an toàn.

-- 1. Hồ sơ người dùng -------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  role text not null default 'auditor' check (role in ('admin', 'auditor')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Tài khoản đăng ký từ app luôn là kiểm kê viên. Vai trò admin chỉ đặt
-- được bằng SQL (xem cuối file), không gửi từ app lên.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Tài khoản đã có từ trước (nếu có) cũng được tạo hồ sơ.
insert into public.profiles (id, full_name)
select id, coalesce(raw_user_meta_data ->> 'full_name', '')
from auth.users
on conflict (id) do nothing;

drop policy if exists "Xem hồ sơ của mình" on public.profiles;
create policy "Xem hồ sơ của mình" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

-- 2. Người tạo phiếu ----------------------------------------------------------

alter table public.audit_records
  add column if not exists created_by uuid
  default auth.uid()
  references auth.users (id) on delete set null;

-- 3. Khoá dữ liệu cho tài khoản đã đăng nhập ---------------------------------

-- Bỏ các policy cũ (mở cho anon/public) trên hai bảng.
do $$
declare p record;
begin
  for p in
    select policyname, tablename from pg_policies
    where schemaname = 'public' and tablename in ('audit_records', 'assets')
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end;
$$;

alter table public.audit_records enable row level security;
alter table public.assets enable row level security;

create policy "Đã đăng nhập: đọc phiếu" on public.audit_records
  for select to authenticated using (true);
create policy "Đã đăng nhập: thêm phiếu" on public.audit_records
  for insert to authenticated
  with check (created_by is null or created_by = (select auth.uid()));
create policy "Đã đăng nhập: cập nhật phiếu của mình" on public.audit_records
  for update to authenticated
  using (created_by is null or created_by = (select auth.uid()))
  with check (created_by = (select auth.uid()));

create policy "Đã đăng nhập: đọc tài sản" on public.assets
  for select to authenticated using (true);
create policy "Đã đăng nhập: thêm tài sản" on public.assets
  for insert to authenticated with check (true);
create policy "Đã đăng nhập: cập nhật tài sản" on public.assets
  for update to authenticated using (true) with check (true);

-- Ảnh chữ ký và ảnh minh chứng: chỉ tài khoản đã đăng nhập được tải lên.
-- Hai bucket vẫn công khai nên đường dẫn ảnh trong phiếu vẫn mở được.
drop policy if exists "Public access signatures 1h6xdx7_0" on storage.objects;
drop policy if exists "Public access signatures 1h6xdx7_1" on storage.objects;
drop policy if exists "evidence anon insert" on storage.objects;
drop policy if exists "evidence anon select" on storage.objects;
drop policy if exists "Đã đăng nhập: tải ảnh lên" on storage.objects;
drop policy if exists "Đã đăng nhập: xem ảnh" on storage.objects;

create policy "Đã đăng nhập: tải ảnh lên" on storage.objects
  for insert to authenticated
  with check (bucket_id in ('signatures', 'evidence'));
create policy "Đã đăng nhập: xem ảnh" on storage.objects
  for select to authenticated
  using (bucket_id in ('signatures', 'evidence'));

-- Tạo tài khoản admin --------------------------------------------------------
-- Tạo người dùng trong Dashboard -> Authentication -> Users -> Add user
-- (tích "Auto Confirm User"), rồi chạy dòng dưới với email đó:
--
--   update public.profiles set role = 'admin', full_name = 'Quản trị viên'
--   where id = (select id from auth.users where email = 'admin@example.com');
