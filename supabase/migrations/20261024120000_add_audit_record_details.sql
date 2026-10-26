-- Bổ sung thông tin hiện trường cho phiếu kiểm kê (khu vực, vị trí, tình trạng, ghi chú).
-- Phải chạy trước khi app phiên bản mới đồng bộ, nếu không upsert sẽ báo lỗi cột không tồn tại.

alter table public.audit_records
  add column if not exists area text,
  add column if not exists location text,
  add column if not exists condition text,
  add column if not exists notes text;

alter table public.audit_records
  drop constraint if exists audit_records_condition_check;

alter table public.audit_records
  add constraint audit_records_condition_check
  check (condition is null or condition in ('good', 'check', 'damaged'));
