-- =====================================================================
-- Promote ONE existing account to admin (run in Supabase SQL Editor).
--
-- 1. The staff member first registers normally (they become 'student').
-- 2. Replace the email below and run this.
--
-- This is the ONLY way to create an admin. The app and the REST API
-- cannot do it (see migration 0002 + test T11).
-- =====================================================================
update public.profiles p
set    role = 'admin'
from   auth.users u
where  u.id = p.id
  and  u.email = 'staff.admin@example.com';   -- <-- change me

-- Check the result:
select u.email, p.role, p.created_at
from public.profiles p
join auth.users u on u.id = p.id
order by p.role, u.email;
