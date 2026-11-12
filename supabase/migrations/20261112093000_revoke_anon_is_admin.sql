-- is_admin() chỉ dùng trong policy cho tài khoản đã đăng nhập: không cho anon
-- gọi qua /rest/v1/rpc/is_admin (cảnh báo 0028 của Supabase advisor).
-- Chạy lại vẫn an toàn.

revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;
