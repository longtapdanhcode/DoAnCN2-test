-- Card 23: ảnh minh chứng hiện trường cho phiếu kiểm kê.
-- Chạy trong Supabase SQL Editor (project DoAnCN2).

-- 1) Cột lưu URL các ảnh (tối đa 3 ảnh mỗi phiếu, do app giới hạn).
alter table public.audit_records
  add column if not exists photo_urls text[] not null default '{}';

-- 2) Bucket công khai chứa ảnh (đọc bằng URL công khai, như bucket signatures).
insert into storage.buckets (id, name, public)
values ('evidence', 'evidence', true)
on conflict (id) do nothing;

-- 3) Cho app (khoá anon) tải ảnh lên và đọc ảnh. Không cho sửa/xoá.
create policy "evidence anon insert"
  on storage.objects for insert to anon
  with check (bucket_id = 'evidence');

create policy "evidence anon select"
  on storage.objects for select to anon
  using (bucket_id = 'evidence');
