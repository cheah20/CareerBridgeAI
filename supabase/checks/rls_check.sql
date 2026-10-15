-- CareerBridge AI — RLS permission check (task 1.2)
--
-- Creates temporary users and data inside one transaction, checks what each
-- role can read/write, prints PASS/FAIL per test, then ROLLS BACK everything.
-- Nothing is left in the database.
--
-- Run:  supabase db query --linked -f supabase/checks/rls_check.sql

begin;

create temporary table results (
  no        serial,
  test      text,
  expected  text,
  actual    text
) on commit drop;

-- Switch to an API role as a given user (called while running as postgres).
create function pg_temp.act_as(api_role text, uid uuid) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', api_role)::text, true);
  perform set_config('request.jwt.claim.sub', coalesce(uid::text, ''), true);
  perform set_config('role', api_role, true);
end;
$$;

create function pg_temp.check(test text, expected text, actual text) returns void
language sql as $$
  insert into results (test, expected, actual) values (test, expected, actual);
$$;

do $$
declare
  -- users
  seeker_a    uuid := 'a0000000-0000-4000-8000-00000000000a';
  seeker_b    uuid := 'a0000000-0000-4000-8000-00000000000b';
  recruiter_c uuid := 'a0000000-0000-4000-8000-00000000000c';
  recruiter_d uuid := 'a0000000-0000-4000-8000-00000000000d';
  admin_e     uuid := 'a0000000-0000-4000-8000-00000000000e';
  hacker_f    uuid := 'a0000000-0000-4000-8000-00000000000f';
  -- data
  company_x   uuid := 'c0000000-0000-4000-8000-00000000000a';  -- verified, member C
  company_y   uuid := 'c0000000-0000-4000-8000-00000000000b';  -- verified, member D
  company_z   uuid := 'c0000000-0000-4000-8000-00000000000c';  -- pending,  member D
  job_x_pub   uuid := 'b0000000-0000-4000-8000-00000000000a';
  job_x_draft uuid := 'b0000000-0000-4000-8000-00000000000b';
  job_y_pub   uuid := 'b0000000-0000-4000-8000-00000000000c';
  resume_a    uuid := 'd0000000-0000-4000-8000-00000000000a';
  resume_b    uuid := 'd0000000-0000-4000-8000-00000000000b';
  app_a       uuid := 'e0000000-0000-4000-8000-00000000000a';
  n    bigint;
  res  text;
  r    text;
begin
  -- ---------------- fixtures (as postgres) ----------------
  insert into auth.users (id, email, raw_user_meta_data) values
    (seeker_a,    'seeker.a@example.test',    '{"full_name":"Seeker A"}'),
    (seeker_b,    'seeker.b@example.test',    '{"full_name":"Seeker B","role":"job_seeker"}'),
    (recruiter_c, 'recruiter.c@example.test', '{"full_name":"Recruiter C","role":"recruiter"}'),
    (recruiter_d, 'recruiter.d@example.test', '{"full_name":"Recruiter D","role":"recruiter"}'),
    (admin_e,     'admin.e@example.test',     '{"full_name":"Admin E"}'),
    (hacker_f,    'hacker.f@example.test',    '{"full_name":"Hacker F","role":"admin"}');
  update public.profiles set role = 'admin' where id = admin_e;  -- developer-granted admin

  insert into public.companies (id, name, verification_status, created_by) values
    (company_x, 'Company X', 'verified', recruiter_c),
    (company_y, 'Company Y', 'verified', recruiter_d),
    (company_z, 'Company Z', 'pending',  recruiter_d);
  insert into public.company_members (company_id, user_id, member_role) values
    (company_x, recruiter_c, 'owner'),
    (company_y, recruiter_d, 'owner'),
    (company_z, recruiter_d, 'owner');

  insert into public.jobs (id, company_id, title, work_type, work_mode, experience_level, status) values
    (job_x_pub,   company_x, 'X Published', 'full_time', 'on_site', 'junior', 'published'),
    (job_x_draft, company_x, 'X Draft',     'full_time', 'remote',  'mid',    'draft'),
    (job_y_pub,   company_y, 'Y Published', 'internship','hybrid',  'entry',  'published');

  insert into public.resumes (id, owner_id, file_name, storage_path, mime_type, file_size_bytes) values
    (resume_a, seeker_a, 'a.pdf', seeker_a || '/a.pdf', 'application/pdf', 1000),
    (resume_b, seeker_b, 'b.pdf', seeker_b || '/b.pdf', 'application/pdf', 1000);

  insert into public.applications (id, job_id, seeker_id, resume_id) values
    (app_a, job_x_pub, seeker_a, resume_a);   -- A applied to Company X

  -- ---------------- sign-up trigger ----------------
  select role::text into r from public.profiles where id = hacker_f;
  perform pg_temp.check('Sign-up asking for admin becomes job_seeker', 'job_seeker', r);
  select role::text into r from public.profiles where id = recruiter_c;
  perform pg_temp.check('Sign-up as recruiter gets recruiter role', 'recruiter', r);
  select count(*) into n from public.seeker_profiles where user_id = recruiter_c;
  perform pg_temp.check('Recruiter has no seeker_profiles row', '0', n::text);

  -- ---------------- Seeker A (applied to Company X) ----------------
  perform pg_temp.act_as('authenticated', seeker_a);
  select count(*) into n from public.profiles;        perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A sees only own profile', '1', n::text);

  perform pg_temp.act_as('authenticated', seeker_a);
  select count(*) into n from public.resumes;         perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A sees only own resume (not B''s)', '1', n::text);

  perform pg_temp.act_as('authenticated', seeker_a);
  select count(*) into n from public.applications;    perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A sees own application', '1', n::text);

  perform pg_temp.act_as('authenticated', seeker_a);
  select count(*) into n from public.jobs;            perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A sees published jobs only (no drafts)', '2', n::text);

  perform pg_temp.act_as('authenticated', seeker_a);
  select count(*) into n from public.companies;       perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A sees verified companies only', '2', n::text);

  begin
    perform pg_temp.act_as('authenticated', seeker_a);
    update public.profiles set role = 'admin' where id = seeker_a;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A cannot make self admin', 'denied', res);

  begin
    perform pg_temp.act_as('authenticated', seeker_a);
    update public.profiles set account_status = 'active' where id = seeker_a;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A cannot change own account_status', 'denied', res);

  perform pg_temp.act_as('authenticated', seeker_a);
  update public.profiles set full_name = 'Seeker A (edited)' where id = seeker_a;
  get diagnostics n = row_count;                      perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A can edit own name', '1', n::text);

  perform pg_temp.act_as('authenticated', seeker_a);
  update public.profiles set full_name = 'hacked' where id = seeker_b;
  get diagnostics n = row_count;                      perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A cannot edit Seeker B''s profile', '0', n::text);

  perform pg_temp.act_as('authenticated', seeker_a);
  update public.seeker_profiles set skills = array['Python'] where user_id = seeker_a;
  get diagnostics n = row_count;                      perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A can edit own skills', '1', n::text);

  begin
    perform pg_temp.act_as('authenticated', seeker_a);
    insert into public.jobs (company_id, title, work_type, work_mode, experience_level, status)
    values (company_x, 'Fake', 'full_time', 'remote', 'entry', 'published');
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A cannot create jobs directly', 'denied', res);

  begin
    perform pg_temp.act_as('authenticated', seeker_a);
    update public.applications set status = 'hired' where id = app_a;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A cannot change own application status', 'denied', res);

  begin
    perform pg_temp.act_as('authenticated', seeker_a);
    delete from public.resumes where id = resume_b;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker A cannot delete resumes directly', 'denied', res);

  -- ---------------- Seeker B (no applications) ----------------
  perform pg_temp.act_as('authenticated', seeker_b);
  select count(*) into n from public.applications;    perform set_config('role', 'none', true);
  perform pg_temp.check('Seeker B cannot see Seeker A''s application', '0', n::text);

  -- ---------------- Recruiter C (Company X, has applicant A) ----------------
  perform pg_temp.act_as('authenticated', recruiter_c);
  select count(*) into n from public.profiles;        perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C sees self + applicant A only', '2', n::text);

  perform pg_temp.act_as('authenticated', recruiter_c);
  select count(*) into n from public.seeker_profiles; perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C sees applicant A''s details only', '1', n::text);

  perform pg_temp.act_as('authenticated', recruiter_c);
  select count(*) into n from public.resumes;         perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C sees only the submitted resume', '1', n::text);

  perform pg_temp.act_as('authenticated', recruiter_c);
  select count(*) into n from public.resumes where id = resume_b;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C cannot see unsubmitted resume B', '0', n::text);

  perform pg_temp.act_as('authenticated', recruiter_c);
  select count(*) into n from public.applications;    perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C sees applications to own jobs', '1', n::text);

  perform pg_temp.act_as('authenticated', recruiter_c);
  select count(*) into n from public.jobs;            perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C sees own draft + all published', '3', n::text);

  perform pg_temp.act_as('authenticated', recruiter_c);
  select count(*) into n from public.application_status_history;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C sees status history of own applications', '1', n::text);

  begin
    perform pg_temp.act_as('authenticated', recruiter_c);
    update public.applications set status = 'rejected' where id = app_a;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C cannot change status directly (FastAPI only)', 'denied', res);

  begin
    perform pg_temp.act_as('authenticated', recruiter_c);
    update public.companies set verification_status = 'verified' where id = company_x;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter C cannot verify own company', 'denied', res);

  -- ---------------- Recruiter D (Company Y verified + Company Z pending, no applicants) ----------------
  perform pg_temp.act_as('authenticated', recruiter_d);
  select count(*) into n from public.profiles;        perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter D sees only own profile', '1', n::text);

  perform pg_temp.act_as('authenticated', recruiter_d);
  select count(*) into n from public.resumes;         perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter D sees no resumes', '0', n::text);

  perform pg_temp.act_as('authenticated', recruiter_d);
  select count(*) into n from public.applications;    perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter D sees no applications of Company X', '0', n::text);

  perform pg_temp.act_as('authenticated', recruiter_d);
  select count(*) into n from public.companies;       perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter D sees verified + own pending company', '3', n::text);

  perform pg_temp.act_as('authenticated', recruiter_d);
  select count(*) into n from public.company_members; perform set_config('role', 'none', true);
  perform pg_temp.check('Recruiter D sees own 2 memberships only', '2', n::text);

  -- ---------------- Admin E ----------------
  perform pg_temp.act_as('authenticated', admin_e);
  select count(*) into n from public.profiles;        perform set_config('role', 'none', true);
  perform pg_temp.check('Admin sees all 6 profiles', '6', n::text);

  perform pg_temp.act_as('authenticated', admin_e);
  select count(*) into n from public.jobs;            perform set_config('role', 'none', true);
  perform pg_temp.check('Admin sees all 3 jobs incl. draft', '3', n::text);

  perform pg_temp.act_as('authenticated', admin_e);
  select count(*) into n from public.applications;    perform set_config('role', 'none', true);
  perform pg_temp.check('Admin sees all applications', '1', n::text);

  perform pg_temp.act_as('authenticated', admin_e);
  select count(*) into n from public.resumes;         perform set_config('role', 'none', true);
  perform pg_temp.check('Admin cannot read resumes directly (backend only)', '0', n::text);

  -- ---------------- Guest (anon) ----------------
  perform pg_temp.act_as('anon', null);
  select count(*) into n from public.jobs;            perform set_config('role', 'none', true);
  perform pg_temp.check('Guest sees published jobs only', '2', n::text);

  perform pg_temp.act_as('anon', null);
  select count(*) into n from public.companies;       perform set_config('role', 'none', true);
  perform pg_temp.check('Guest sees verified companies only', '2', n::text);

  begin
    perform pg_temp.act_as('anon', null);
    select count(*) into n from public.profiles;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Guest cannot read profiles', 'denied', res);

  begin
    perform pg_temp.act_as('anon', null);
    select count(*) into n from public.resumes;
    res := 'allowed';
  exception when insufficient_privilege then res := 'denied';
  end;
  perform set_config('role', 'none', true);
  perform pg_temp.check('Guest cannot read resumes', 'denied', res);

  -- ---------------- Business-rule triggers (as postgres / backend) ----------------
  update public.applications set status = 'under_review' where id = app_a;
  select count(*) into n from public.application_status_history where application_id = app_a;
  perform pg_temp.check('Status change is recorded in history', '2', n::text);

  insert into public.resumes (owner_id, file_name, storage_path, mime_type, file_size_bytes)
  select seeker_a, 'r' || i || '.pdf', seeker_a || '/r' || i || '.pdf', 'application/pdf', 1000
  from generate_series(2, 5) as i;   -- A now has 5 resumes
  begin
    insert into public.resumes (owner_id, file_name, storage_path, mime_type, file_size_bytes)
    values (seeker_a, 'r6.pdf', seeker_a || '/r6.pdf', 'application/pdf', 1000);
    res := 'allowed';
  exception when check_violation then res := 'blocked';
  end;
  perform pg_temp.check('6th resume is blocked (max 5)', 'blocked', res);

  begin
    insert into public.resumes (owner_id, file_name, storage_path, mime_type, file_size_bytes)
    values (seeker_b, 'big.pdf', seeker_b || '/big.pdf', 'application/pdf', 10485761);
    res := 'allowed';
  exception when check_violation then res := 'blocked';
  end;
  perform pg_temp.check('File over 10 MB is blocked', 'blocked', res);

  begin
    insert into public.applications (job_id, seeker_id, resume_id) values (job_x_pub, seeker_a, resume_a);
    res := 'allowed';
  exception when unique_violation then res := 'blocked';
  end;
  perform pg_temp.check('Duplicate application to same job is blocked', 'blocked', res);
end;
$$;

-- Report by raising an error: this guarantees the whole transaction is rolled
-- back no matter how the client runs the script.
do $$
declare
  report text;
  failed int;
begin
  select string_agg(format('%s %s. %s (expected %s, got %s)',
           case when expected = actual then 'PASS' else 'FAIL' end,
           no, test, expected, actual), E'\n' order by no),
         count(*) filter (where expected is distinct from actual)
    into report, failed
  from results;
  raise exception E'RLS CHECK DONE (rolled back) — % failed of %\n%',
    failed, (select count(*) from results), report;
end;
$$;

rollback;
