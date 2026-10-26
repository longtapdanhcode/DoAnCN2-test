-- Lưu tên tài sản và thông tin người ký xác nhận cùng phiếu kiểm kê.

alter table public.audit_records
  add column if not exists asset_name text,
  add column if not exists signer_name text,
  add column if not exists signer_role text;
