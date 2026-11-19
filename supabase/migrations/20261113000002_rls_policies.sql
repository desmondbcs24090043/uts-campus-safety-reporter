-- =====================================================================
-- Migration 0002 : Row Level Security (RLS) + table permissions
-- Owner          : Member 4
--
-- Supabase exposes every table in "public" through its REST API.
-- The publishable/anon key is inside the app, so ANYONE could call the API.
-- Security therefore lives HERE in the database, never in Flutter code.
--
-- Two layers of protection are used:
--   Layer 1 - GRANTs   : which COLUMNS a logged-in user may insert/update at all.
--   Layer 2 - POLICIES : which ROWS a user may see / change (RLS).
--
-- RESULTING RULES (matches Project Specification section 4)
--   +-----------------------+----------------------+-------------------------+
--   | action                | student              | admin                   |
--   +-----------------------+----------------------+-------------------------+
--   | read own profile      | yes                  | yes (all profiles)      |
--   | change any role       | NO                   | NO (only SQL Editor)    |
--   | create report         | own, status=pending  | (not needed)            |
--   | read reports          | ONLY their own       | ALL                     |
--   | change report status  | NO                   | yes (status column only)|
--   | edit other columns    | NO                   | NO                      |
--   | delete report         | NO                   | NO                      |
--   | anything while logged out (anon)            -> NO                      |
--   +-----------------------+----------------------+-------------------------+
-- =====================================================================


-- ---------------------------------------------------------------------
-- Turn RLS ON. With RLS on and no matching policy, access is DENIED.
-- ---------------------------------------------------------------------
alter table public.profiles         enable row level security;
alter table public.incident_reports enable row level security;


-- ---------------------------------------------------------------------
-- Layer 1: GRANTs (column-level privileges)
-- Supabase grants ALL to anon/authenticated by default; we tighten it.
-- ---------------------------------------------------------------------

-- Logged-out visitors get nothing.
revoke all on public.profiles         from anon;
revoke all on public.incident_reports from anon;

-- profiles: logged-in users may only READ. Rows are created by the
-- handle_new_user() trigger; roles are changed only in SQL Editor.
revoke all    on public.profiles from authenticated;
grant  select on public.profiles to   authenticated;

-- incident_reports:
revoke all    on public.incident_reports from authenticated;
grant  select on public.incident_reports to   authenticated;

-- INSERT: only these columns may be sent by the app.
--   id, status, created_at, updated_at are NOT in the list, so they always
--   take their defaults (status is therefore always 'pending' on creation).
grant insert (reporter_id, category, description, latitude, longitude, photo_path)
  on public.incident_reports to authenticated;

-- UPDATE: only the status column may ever be updated through the API.
--   (Policies below then restrict WHO may do it -> admins only.)
grant update (status) on public.incident_reports to authenticated;

-- No DELETE grant at all -> nobody can delete reports through the API.


-- ---------------------------------------------------------------------
-- Layer 2: POLICIES on profiles
-- (select auth.uid()) is wrapped in a sub-select for performance,
-- as recommended by Supabase.
-- ---------------------------------------------------------------------
drop policy if exists "profiles: read own"        on public.profiles;
drop policy if exists "profiles: admin reads all" on public.profiles;

create policy "profiles: read own"
  on public.profiles for select
  to authenticated
  using ( id = (select auth.uid()) );

create policy "profiles: admin reads all"
  on public.profiles for select
  to authenticated
  using ( (select public.is_admin()) );


-- ---------------------------------------------------------------------
-- Layer 2: POLICIES on incident_reports
-- ---------------------------------------------------------------------
drop policy if exists "reports: student reads own"     on public.incident_reports;
drop policy if exists "reports: admin reads all"       on public.incident_reports;
drop policy if exists "reports: student creates own"   on public.incident_reports;
drop policy if exists "reports: admin updates status"  on public.incident_reports;

-- SELECT: students see only rows they reported.
create policy "reports: student reads own"
  on public.incident_reports for select
  to authenticated
  using ( reporter_id = (select auth.uid()) );

-- SELECT: admins see every row.
create policy "reports: admin reads all"
  on public.incident_reports for select
  to authenticated
  using ( (select public.is_admin()) );

-- INSERT: you can only create a report AS YOURSELF, it must start as
-- 'pending', and the photo (if any) must be inside YOUR OWN storage folder.
create policy "reports: student creates own"
  on public.incident_reports for insert
  to authenticated
  with check (
        reporter_id = (select auth.uid())
    and status = 'pending'
    and (
          photo_path is null
       or photo_path like ((select auth.uid())::text || '/%')
    )
  );

-- UPDATE: only admins. Combined with the column grant above, an admin can
-- change ONLY the status column. Students have no UPDATE policy, so any
-- update they attempt affects 0 rows.
create policy "reports: admin updates status"
  on public.incident_reports for update
  to authenticated
  using      ( (select public.is_admin()) )
  with check ( (select public.is_admin()) );
