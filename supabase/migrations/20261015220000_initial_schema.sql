-- CareerBridge AI database schema v1
-- Tables: profiles, seeker_profiles, companies, company_members, jobs,
--         resumes, applications, application_status_history
-- Access model (architecture B):
--   * Flutter reads directly through the Data API, limited by RLS.
--   * Writes with business rules (jobs, companies, uploads, applications)
--     go through FastAPI using the secret key (service_role bypasses RLS).
--   * Users may directly edit only their own basic profile fields.
--   * Guests (anon) may browse published jobs and verified companies only.

-- Enum types
create type public.user_role as enum ('job_seeker', 'recruiter', 'admin');
create type public.account_status as enum ('active', 'disabled', 'pending_deletion');
create type public.verification_status as enum ('pending', 'verified', 'rejected', 're_review');
create type public.company_member_role as enum ('owner', 'recruiter');
create type public.work_type as enum ('full_time', 'part_time', 'contract', 'internship', 'temporary');
create type public.work_mode as enum ('on_site', 'remote', 'hybrid');
create type public.experience_level as enum ('entry', 'junior', 'mid', 'senior', 'lead');
create type public.job_status as enum ('draft', 'pending_review', 'published', 'rejected', 'closed');
create type public.task_status as enum ('pending', 'processing', 'completed', 'failed');
create type public.application_status as enum (
  'applied', 'under_review', 'shortlisted', 'interview', 'offer', 'hired', 'rejected', 'withdrawn'
);

-- Shared trigger: keep updated_at current
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Tables

-- One row per user, created automatically on sign-up.
create table public.profiles (
  id                     uuid primary key references auth.users (id) on delete cascade,
  role                   public.user_role not null default 'job_seeker',
  full_name              text not null default '',
  email                  text,
  phone                  text,
  location               text,
  avatar_path            text,
  account_status         public.account_status not null default 'active',
  deletion_requested_at  timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

-- Job Seeker details used for matching. Lists are kept as arrays/JSON in v1.
create table public.seeker_profiles (
  user_id              uuid primary key references public.profiles (id) on delete cascade,
  headline             text,
  summary              text,
  skills               text[] not null default '{}',
  education            jsonb not null default '[]'::jsonb,
  experience           jsonb not null default '[]'::jsonb,
  years_experience     numeric(4, 1) check (years_experience >= 0),
  preferred_locations  text[] not null default '{}',
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create table public.companies (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null check (length(trim(name)) > 0),
  registration_no      text,
  industry             text,
  website              text,
  description          text,
  location             text,
  logo_path            text,
  proof_document_path  text,
  verification_status  public.verification_status not null default 'pending',
  verified_by          uuid references public.profiles (id) on delete set null,
  verified_at          timestamptz,
  rejection_reason     text,
  created_by           uuid references public.profiles (id) on delete set null,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- Which recruiters manage which companies (one recruiter may manage many).
create table public.company_members (
  company_id   uuid not null references public.companies (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  member_role  public.company_member_role not null default 'recruiter',
  created_at   timestamptz not null default now(),
  primary key (company_id, user_id)
);

create table public.jobs (
  id                     uuid primary key default gen_random_uuid(),
  company_id             uuid not null references public.companies (id) on delete restrict,
  created_by             uuid references public.profiles (id) on delete set null,
  title                  text not null check (length(trim(title)) > 0),
  description            text not null default '',
  location               text,
  work_type              public.work_type not null,
  work_mode              public.work_mode not null,
  experience_level       public.experience_level not null,
  salary_min             numeric(12, 2) check (salary_min >= 0),
  salary_max             numeric(12, 2) check (salary_max >= 0),
  currency               char(3) not null default 'MYR',
  required_skills        text[] not null default '{}',
  education_requirement  text,
  industry               text,
  vacancy_count          integer not null default 1 check (vacancy_count > 0),
  application_deadline   date,
  status                 public.job_status not null default 'draft',
  reviewed_by            uuid references public.profiles (id) on delete set null,
  reviewed_at            timestamptz,
  review_note            text,
  published_at           timestamptz,
  closed_at              timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (salary_min is null or salary_max is null or salary_min <= salary_max)
);

-- Resume metadata. The original file lives in the private "resumes" bucket.
create table public.resumes (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null references public.profiles (id) on delete cascade,
  file_name        text not null,
  storage_path     text not null unique,
  mime_type        text not null check (mime_type in (
                     'application/pdf',
                     'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                     'image/jpeg',
                     'image/png',
                     'image/webp')),
  file_size_bytes  bigint not null check (file_size_bytes > 0 and file_size_bytes <= 10485760),
  parse_status     public.task_status not null default 'pending',
  parsed_markdown  text,
  parsed_data      jsonb,
  parse_error      text,
  parsed_at        timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table public.applications (
  id            uuid primary key default gen_random_uuid(),
  job_id        uuid not null references public.jobs (id) on delete restrict,
  seeker_id     uuid references public.profiles (id) on delete set null,
  resume_id     uuid references public.resumes (id) on delete set null,
  status        public.application_status not null default 'applied',
  match_score   numeric(5, 2) check (match_score between 0 and 100),
  cover_note    text,
  applied_at    timestamptz not null default now(),
  withdrawn_at  timestamptz,
  updated_at    timestamptz not null default now(),
  unique (job_id, seeker_id)
);

create table public.application_status_history (
  id              bigint generated always as identity primary key,
  application_id  uuid not null references public.applications (id) on delete cascade,
  from_status     public.application_status,
  to_status       public.application_status not null,
  changed_by      uuid references public.profiles (id) on delete set null,
  note            text,
  changed_at      timestamptz not null default now()
);

-- Indexes (foreign keys and common filters)
create index on public.profiles (role);
create index on public.company_members (user_id);
create index on public.companies (verification_status);
create index on public.jobs (company_id);
create index on public.jobs (status);
create index on public.resumes (owner_id);
create index on public.applications (seeker_id);
create index on public.applications (resume_id);
create index on public.applications (status);
create index on public.application_status_history (application_id);

-- updated_at triggers
create trigger set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.seeker_profiles
  for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.companies
  for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.jobs
  for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.resumes
  for each row execute function public.set_updated_at();
create trigger set_updated_at before update on public.applications
  for each row execute function public.set_updated_at();

-- Business-rule triggers

-- Sign-up: create the profile. Only job_seeker / recruiter can be chosen;
-- admin is never accepted from sign-up data.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role public.user_role;
begin
  requested_role := case new.raw_user_meta_data ->> 'role'
                      when 'recruiter' then 'recruiter'::public.user_role
                      else 'job_seeker'::public.user_role
                    end;

  insert into public.profiles (id, role, full_name, email)
  values (new.id, requested_role, coalesce(new.raw_user_meta_data ->> 'full_name', ''), new.email);

  if requested_role = 'job_seeker' then
    insert into public.seeker_profiles (user_id) values (new.id);
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep at most 5 resumes per user (storage budget on the free plan).
create function public.enforce_resume_limit()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.resumes where owner_id = new.owner_id) >= 5 then
    raise exception 'Resume limit reached: delete an older resume before uploading a new one.'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger enforce_resume_limit before insert on public.resumes
  for each row execute function public.enforce_resume_limit();

-- Record every application status change.
create function public.log_application_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.application_status_history (application_id, from_status, to_status, changed_by)
    values (new.id, null, new.status, auth.uid());
  elsif new.status is distinct from old.status then
    insert into public.application_status_history (application_id, from_status, to_status, changed_by)
    values (new.id, old.status, new.status, auth.uid());
  end if;
  return new;
end;
$$;

create trigger log_application_status
  after insert or update of status on public.applications
  for each row execute function public.log_application_status();

-- Helper functions for RLS (security definer avoids recursive policy checks)
create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and account_status = 'active'
  );
$$;

create function public.is_company_member(target_company uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.company_members
    where company_id = target_company and user_id = auth.uid()
  );
$$;

-- True when the job seeker has applied to a job of a company the caller manages.
create function public.is_applicant_of_my_company(target_seeker uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.applications a
    join public.jobs j on j.id = a.job_id
    join public.company_members m on m.company_id = j.company_id
    where a.seeker_id = target_seeker and m.user_id = auth.uid()
  );
$$;

-- True when the resume was submitted to a job of a company the caller manages.
create function public.is_resume_shared_with_me(target_resume uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.applications a
    join public.jobs j on j.id = a.job_id
    join public.company_members m on m.company_id = j.company_id
    where a.resume_id = target_resume and m.user_id = auth.uid()
  );
$$;

revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_company_member(uuid) from public, anon;
revoke execute on function public.is_applicant_of_my_company(uuid) from public, anon;
revoke execute on function public.is_resume_shared_with_me(uuid) from public, anon;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.log_application_status() from public, anon, authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_company_member(uuid) to authenticated;
grant execute on function public.is_applicant_of_my_company(uuid) to authenticated;
grant execute on function public.is_resume_shared_with_me(uuid) to authenticated;

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.seeker_profiles enable row level security;
alter table public.companies enable row level security;
alter table public.company_members enable row level security;
alter table public.jobs enable row level security;
alter table public.resumes enable row level security;
alter table public.applications enable row level security;
alter table public.application_status_history enable row level security;

-- profiles
create policy "Users read own profile" on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy "Admins read all profiles" on public.profiles
  for select to authenticated using ((select public.is_admin()));
create policy "Recruiters read applicant profiles" on public.profiles
  for select to authenticated using (public.is_applicant_of_my_company(id));
create policy "Users update own profile" on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- seeker_profiles
create policy "Seekers read own details" on public.seeker_profiles
  for select to authenticated using (user_id = (select auth.uid()));
create policy "Recruiters read applicant details" on public.seeker_profiles
  for select to authenticated using (public.is_applicant_of_my_company(user_id));
create policy "Seekers update own details" on public.seeker_profiles
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- companies
create policy "Guests read verified companies" on public.companies
  for select to anon using (verification_status = 'verified');
create policy "Users read verified or own companies" on public.companies
  for select to authenticated
  using (verification_status = 'verified'
         or public.is_company_member(id)
         or (select public.is_admin()));

-- company_members
create policy "Members read own memberships" on public.company_members
  for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));

-- jobs
create policy "Guests read published jobs" on public.jobs
  for select to anon using (status = 'published');
create policy "Users read published or own company jobs" on public.jobs
  for select to authenticated
  using (status = 'published'
         or public.is_company_member(company_id)
         or (select public.is_admin()));

-- resumes (Admins access resumes only through the backend when necessary)
create policy "Seekers read own resumes" on public.resumes
  for select to authenticated using (owner_id = (select auth.uid()));
create policy "Recruiters read submitted resumes" on public.resumes
  for select to authenticated using (public.is_resume_shared_with_me(id));

-- applications
create policy "Seekers read own applications" on public.applications
  for select to authenticated using (seeker_id = (select auth.uid()));
create policy "Recruiters read applications to their jobs" on public.applications
  for select to authenticated
  using (exists (select 1 from public.jobs j
                 where j.id = job_id and public.is_company_member(j.company_id)));
create policy "Admins read all applications" on public.applications
  for select to authenticated using ((select public.is_admin()));

-- application_status_history: visible to whoever can see the application
create policy "Read history of visible applications" on public.application_status_history
  for select to authenticated
  using (exists (select 1 from public.applications a where a.id = application_id));

-- Table privileges (new tables are not exposed automatically in this project)
grant all on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;

grant select on public.profiles, public.seeker_profiles, public.companies,
  public.company_members, public.jobs, public.resumes, public.applications,
  public.application_status_history to authenticated;

-- Direct edits limited to safe columns (role / status cannot be changed by users).
grant update (full_name, phone, location, avatar_path) on public.profiles to authenticated;
grant update (headline, summary, skills, education, experience, years_experience, preferred_locations)
  on public.seeker_profiles to authenticated;

-- Guests: public columns only.
grant select (id, name, industry, website, description, location, logo_path)
  on public.companies to anon;
grant select (id, company_id, title, description, location, work_type, work_mode,
  experience_level, salary_min, salary_max, currency, required_skills,
  education_requirement, industry, vacancy_count, application_deadline,
  status, published_at)
  on public.jobs to anon;

-- Private storage buckets (uploads go through FastAPI)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('resumes', 'resumes', false, 10485760, array[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg', 'image/png', 'image/webp']),
  ('company-documents', 'company-documents', false, 10485760, array[
    'application/pdf', 'image/jpeg', 'image/png', 'image/webp']);

-- Files are stored as <user_id>/<file>; owners can read their own folder.
create policy "Owners read own resume files" on storage.objects
  for select to authenticated
  using (bucket_id = 'resumes' and (storage.foldername(name))[1] = (select auth.uid())::text);
