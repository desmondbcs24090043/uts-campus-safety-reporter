-- =====================================================================
-- RLS / permission tests : authorised AND unauthorised access
-- Owner : Member 4
--
-- HOW TO RUN
--   Supabase Dashboard -> SQL Editor -> paste this whole file -> Run.
--   The last result is a table: every row should say PASS.
--   Screenshot it for the Pull Request / ITPM evidence.
--
-- SAFE TO RUN ON THE SHARED PROJECT
--   It creates 3 temporary fake users (student 1, student 2, admin) with
--   fixed ids, runs the tests while "pretending" to be each user, and then
--   deletes the fake users again (their profiles/reports are deleted too).
--
-- HOW "PRETENDING" WORKS
--   set role authenticated / anon          -> same DB role the REST API uses
--   request.jwt.claims = {"sub": "<id>"}   -> what auth.uid() returns
-- =====================================================================

-- ---------- 0. Fixed test ids ----------------------------------------
--   student 1 : 00000000-0000-4000-8000-0000000000a1
--   student 2 : 00000000-0000-4000-8000-0000000000a2
--   admin     : 00000000-0000-4000-8000-0000000000ad
--   report of student 2 : 00000000-0000-4000-8000-0000000000f2

reset role;
select set_config('request.jwt.claims', '', false);

-- Clean leftovers from an earlier failed run.
delete from auth.users where id in (
  '00000000-0000-4000-8000-0000000000a1',
  '00000000-0000-4000-8000-0000000000a2',
  '00000000-0000-4000-8000-0000000000ad'
);

-- ---------- 1. Arrange (as database owner) ---------------------------
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000000000a1', 'rls_student1@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000000000a2', 'rls_student2@test.local', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000000000ad', 'rls_admin@test.local',    'authenticated', 'authenticated');

-- T00: the sign-up trigger must have created STUDENT profiles for all three.
do $$
declare n int;
begin
  select count(*) into n from public.profiles
  where id in ('00000000-0000-4000-8000-0000000000a1',
               '00000000-0000-4000-8000-0000000000a2',
               '00000000-0000-4000-8000-0000000000ad')
    and role = 'student';
  perform set_config('rls.t00', case when n = 3 then 'PASS' else 'FAIL (' || n || ' student profiles)' end, false);
end $$;

-- Promote the test admin (this is exactly how a real admin is created).
update public.profiles set role = 'admin' where id = '00000000-0000-4000-8000-0000000000ad';

-- A report that belongs to student 2 (old timestamps, so T18 can prove
-- the updated_at trigger really runs).
insert into public.incident_reports (id, reporter_id, category, description, latitude, longitude, photo_path,
                                     created_at, updated_at)
values ('00000000-0000-4000-8000-0000000000f2', '00000000-0000-4000-8000-0000000000a2',
        'lighting', 'Street light broken near library', 1.5, 111.8,
        '00000000-0000-4000-8000-0000000000a2/seed.jpg',
        '2000-01-01', '2000-01-01');


-- ---------- 2. Logged-out visitor (anon) -----------------------------
set role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', false);

-- T01 anon cannot read reports
do $$
begin
  perform count(*) from public.incident_reports;
  perform set_config('rls.t01', 'FAIL (anon could read)', false);
exception when insufficient_privilege then
  perform set_config('rls.t01', 'PASS', false);
end $$;

-- T02 anon cannot create a report
do $$
begin
  insert into public.incident_reports (reporter_id, category, description, latitude, longitude)
  values ('00000000-0000-4000-8000-0000000000a1', 'other', 'anon attack test', 1, 1);
  perform set_config('rls.t02', 'FAIL (anon could insert)', false);
exception when insufficient_privilege then
  perform set_config('rls.t02', 'PASS', false);
end $$;


-- ---------- 3. Student 1 ---------------------------------------------
reset role;
set role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000000000a1","role":"authenticated"}', false);

-- T03 student can create own report; status defaults to pending
do $$
declare v_status text;
begin
  insert into public.incident_reports (category, description, latitude, longitude, photo_path)
  values ('safety_hazard', 'Wet floor at Block A lobby', 2.3, 111.83,
          '00000000-0000-4000-8000-0000000000a1/photo1.jpg')
  returning status into v_status;
  perform set_config('rls.t03', case when v_status = 'pending' then 'PASS' else 'FAIL (status=' || v_status || ')' end, false);
exception when others then
  perform set_config('rls.t03', 'FAIL (' || sqlerrm || ')', false);
end $$;

-- T04 student cannot create a report pretending to be student 2
do $$
begin
  insert into public.incident_reports (reporter_id, category, description, latitude, longitude)
  values ('00000000-0000-4000-8000-0000000000a2', 'other', 'impersonation test', 1, 1);
  perform set_config('rls.t04', 'FAIL (impersonation allowed)', false);
exception when insufficient_privilege then
  perform set_config('rls.t04', 'PASS', false);
end $$;

-- T05 student cannot create a report that is already 'resolved'
do $$
begin
  insert into public.incident_reports (category, description, latitude, longitude, status)
  values ('other', 'status injection test', 1, 1, 'resolved');
  perform set_config('rls.t05', 'FAIL (status injection allowed)', false);
exception when insufficient_privilege then
  perform set_config('rls.t05', 'PASS', false);
end $$;

-- T06 student cannot point photo_path at another user's folder
do $$
begin
  insert into public.incident_reports (category, description, latitude, longitude, photo_path)
  values ('other', 'photo path test', 1, 1, '00000000-0000-4000-8000-0000000000a2/seed.jpg');
  perform set_config('rls.t06', 'FAIL (foreign photo_path allowed)', false);
exception when insufficient_privilege then
  perform set_config('rls.t06', 'PASS', false);
end $$;

-- T07 student sees ONLY own reports (student 2's report is invisible)
do $$
declare v_own int; v_other int;
begin
  select count(*) filter (where reporter_id =  '00000000-0000-4000-8000-0000000000a1'),
         count(*) filter (where reporter_id <> '00000000-0000-4000-8000-0000000000a1')
    into v_own, v_other
  from public.incident_reports;
  perform set_config('rls.t07',
    case when v_own >= 1 and v_other = 0 then 'PASS'
         else 'FAIL (own=' || v_own || ', other=' || v_other || ')' end, false);
end $$;

-- T08 student CANNOT change report status (not even on own report)
do $$
declare n int;
begin
  update public.incident_reports set status = 'resolved'
  where reporter_id = '00000000-0000-4000-8000-0000000000a1';
  get diagnostics n = row_count;
  perform set_config('rls.t08', case when n = 0 then 'PASS' else 'FAIL (' || n || ' rows changed)' end, false);
exception when insufficient_privilege then
  perform set_config('rls.t08', 'PASS', false);
end $$;

-- T09 student cannot edit description of a report
do $$
begin
  update public.incident_reports set description = 'tampered'
  where reporter_id = '00000000-0000-4000-8000-0000000000a1';
  perform set_config('rls.t09', 'FAIL (description edited)', false);
exception when insufficient_privilege then
  perform set_config('rls.t09', 'PASS', false);
end $$;

-- T10 student cannot delete a report
do $$
begin
  delete from public.incident_reports where reporter_id = '00000000-0000-4000-8000-0000000000a1';
  perform set_config('rls.t10', 'FAIL (delete allowed)', false);
exception when insufficient_privilege then
  perform set_config('rls.t10', 'PASS', false);
end $$;

-- T11 student cannot promote themselves to admin
do $$
begin
  update public.profiles set role = 'admin' where id = '00000000-0000-4000-8000-0000000000a1';
  perform set_config('rls.t11', 'FAIL (self-promotion allowed)', false);
exception when insufficient_privilege then
  perform set_config('rls.t11', 'PASS', false);
end $$;

-- T12 student sees only their own profile
do $$
declare n int;
begin
  select count(*) into n from public.profiles;
  perform set_config('rls.t12', case when n = 1 then 'PASS' else 'FAIL (sees ' || n || ' profiles)' end, false);
end $$;


-- ---------- 4. Admin -------------------------------------------------
reset role;
set role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000000000ad","role":"authenticated"}', false);

-- T13 admin sees reports from BOTH students
do $$
declare n int;
begin
  select count(distinct reporter_id) into n from public.incident_reports
  where reporter_id in ('00000000-0000-4000-8000-0000000000a1', '00000000-0000-4000-8000-0000000000a2');
  perform set_config('rls.t13', case when n = 2 then 'PASS' else 'FAIL (saw ' || n || ' reporters)' end, false);
end $$;

-- T14 admin CAN change status pending -> in_progress
do $$
declare n int;
begin
  update public.incident_reports set status = 'in_progress'
  where id = '00000000-0000-4000-8000-0000000000f2';
  get diagnostics n = row_count;
  perform set_config('rls.t14', case when n = 1 then 'PASS' else 'FAIL (' || n || ' rows changed)' end, false);
exception when others then
  perform set_config('rls.t14', 'FAIL (' || sqlerrm || ')', false);
end $$;

-- T15 admin cannot use an invalid status value
do $$
begin
  update public.incident_reports set status = 'done'
  where id = '00000000-0000-4000-8000-0000000000f2';
  perform set_config('rls.t15', 'FAIL (invalid status accepted)', false);
exception when check_violation then
  perform set_config('rls.t15', 'PASS', false);
end $$;

-- T16 admin cannot edit the student's description (status only)
do $$
begin
  update public.incident_reports set description = 'admin tampered'
  where id = '00000000-0000-4000-8000-0000000000f2';
  perform set_config('rls.t16', 'FAIL (admin edited description)', false);
exception when insufficient_privilege then
  perform set_config('rls.t16', 'PASS', false);
end $$;

-- T17 admin cannot delete reports through the API
do $$
begin
  delete from public.incident_reports where id = '00000000-0000-4000-8000-0000000000f2';
  perform set_config('rls.t17', 'FAIL (admin delete allowed)', false);
exception when insufficient_privilege then
  perform set_config('rls.t17', 'PASS', false);
end $$;


-- ---------- 5. Back to owner: verify + clean up ----------------------
reset role;
select set_config('request.jwt.claims', '', false);

-- T18 updated_at trigger moved forward after the admin's status change
do $$
declare ok boolean;
begin
  select updated_at > '2000-01-02'::timestamptz and status = 'in_progress' into ok
  from public.incident_reports where id = '00000000-0000-4000-8000-0000000000f2';
  perform set_config('rls.t18', case when ok then 'PASS' else 'FAIL' end, false);
end $$;

delete from auth.users where id in (
  '00000000-0000-4000-8000-0000000000a1',
  '00000000-0000-4000-8000-0000000000a2',
  '00000000-0000-4000-8000-0000000000ad'
);

-- ---------- 6. Results -----------------------------------------------
select test_id, who, expectation, coalesce(current_setting('rls.' || lower(test_id), true), 'NOT RUN') as result
from (values
  ('T00', 'system',    'New sign-ups always get role = student'),
  ('T01', 'anon',      'Cannot read reports'),
  ('T02', 'anon',      'Cannot create reports'),
  ('T03', 'student 1', 'Can create own report (starts as pending)'),
  ('T04', 'student 1', 'Cannot create report as another student'),
  ('T05', 'student 1', 'Cannot set status when creating'),
  ('T06', 'student 1', 'Cannot link photo from another user''s folder'),
  ('T07', 'student 1', 'Sees only own reports'),
  ('T08', 'student 1', 'Cannot change report status'),
  ('T09', 'student 1', 'Cannot edit report description'),
  ('T10', 'student 1', 'Cannot delete reports'),
  ('T11', 'student 1', 'Cannot promote self to admin'),
  ('T12', 'student 1', 'Sees only own profile'),
  ('T13', 'admin',     'Sees reports from all students'),
  ('T14', 'admin',     'Can change status pending -> in_progress'),
  ('T15', 'admin',     'Invalid status value is rejected'),
  ('T16', 'admin',     'Cannot edit report content (status only)'),
  ('T17', 'admin',     'Cannot delete reports'),
  ('T18', 'system',    'updated_at is refreshed on status change')
) as t(test_id, who, expectation)
order by test_id;
