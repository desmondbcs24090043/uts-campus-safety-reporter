-- =====================================================================
-- Migration 0001 : Shared schema (profiles + incident_reports)
-- Project        : UTS Campus Safety Reporter
-- Owner          : Member 4 (Supabase + REST API + Web Admin)
--
-- HOW TO APPLY (no CLI needed):
--   Supabase Dashboard -> SQL Editor -> New query -> paste this whole file -> Run.
--   Run the migrations IN ORDER: 0001 -> 0002 -> 0003.
--
-- WHAT THIS FILE DOES
--   1. Creates the two shared tables agreed in the Project Specification:
--        profiles        (id, role, created_at)
--        incident_reports(id, reporter_id, category, description,
--                         latitude, longitude, photo_path, status,
--                         created_at, updated_at)
--   2. Adds CHECK constraints so bad data can never be stored
--      (e.g. status must be pending / in_progress / resolved).
--   3. Auto-creates a 'student' profile for every new sign-up, so the
--      public registration form can NEVER create an admin.
--   4. Keeps updated_at correct automatically.
--   5. Adds an is_admin() helper used by the security policies in 0002/0003.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. profiles : one row per auth user, holds the role
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  role        text not null default 'student'
              check (role in ('student', 'admin')),
  created_at  timestamptz not null default now()
);

comment on table  public.profiles      is 'One row per user. role decides student vs admin access.';
comment on column public.profiles.role is 'student | admin. Only changed manually by the project owner in SQL Editor.';


-- ---------------------------------------------------------------------
-- 2. incident_reports : the reports students submit
-- ---------------------------------------------------------------------
create table if not exists public.incident_reports (
  id           uuid primary key default gen_random_uuid(),

  -- Defaults to the logged-in user, so the app does not even need to send it.
  reporter_id  uuid not null default auth.uid()
               references public.profiles (id) on delete cascade,

  -- Agreed category list (team can change it later via a NEW migration).
  category     text not null
               check (category in (
                 'safety_hazard',        -- e.g. broken railing, slippery floor
                 'facility_damage',      -- e.g. broken door, leaking pipe
                 'suspicious_activity',
                 'lighting',             -- dark walkway, broken street light
                 'other'
               )),

  description  text not null
               check (char_length(btrim(description)) between 5 and 1000),

  latitude     double precision not null check (latitude  between -90  and 90),
  longitude    double precision not null check (longitude between -180 and 180),

  -- Path INSIDE the private 'report-photos' bucket, e.g. '<user-id>/1731480000000.jpg'
  -- (NOT a public URL). Nullable so a report can still be saved if the photo is optional.
  photo_path   text,

  -- The ONLY three values allowed everywhere (spec section 2).
  status       text not null default 'pending'
               check (status in ('pending', 'in_progress', 'resolved')),

  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table  public.incident_reports        is 'Campus safety / facility reports submitted by students.';
comment on column public.incident_reports.status is 'pending -> in_progress -> resolved. Only admins may change it.';

-- Indexes for the two most common queries:
--   student: "my reports, newest first"   admin: "all reports filtered by status, newest first"
create index if not exists incident_reports_reporter_created_idx
  on public.incident_reports (reporter_id, created_at desc);
create index if not exists incident_reports_status_created_idx
  on public.incident_reports (status, created_at desc);


-- ---------------------------------------------------------------------
-- 3. Keep updated_at fresh on every UPDATE
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists incident_reports_set_updated_at on public.incident_reports;
create trigger incident_reports_set_updated_at
  before update on public.incident_reports
  for each row execute function public.set_updated_at();


-- ---------------------------------------------------------------------
-- 4. Auto-create a STUDENT profile whenever someone registers
--    The role is hard-coded to 'student'. Anything the app puts in the
--    sign-up metadata (e.g. {"role":"admin"}) is IGNORED on purpose.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer          -- runs with owner rights so it can write to profiles
set search_path = ''
as $$
begin
  insert into public.profiles (id, role)
  values (new.id, 'student')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Back-fill: users who registered BEFORE this migration also get a profile.
insert into public.profiles (id, role)
select u.id, 'student' from auth.users u
on conflict (id) do nothing;


-- ---------------------------------------------------------------------
-- 5. is_admin() helper
--    SECURITY DEFINER lets it read profiles without being blocked by RLS
--    (avoids "infinite recursion" in the profiles policy).
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$;

revoke execute on function public.is_admin() from public, anon;
grant  execute on function public.is_admin() to authenticated;
-- Note: handle_new_user() and set_updated_at() return type "trigger", so
-- PostgreSQL refuses to run them except as triggers -> not callable via REST.
