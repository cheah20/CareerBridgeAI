-- Move RLS helper functions out of the API-exposed "public" schema so they
-- cannot be called through /rest/v1/rpc. Existing policies keep working
-- because PostgreSQL references functions by OID, not by name.
-- Fixes Supabase security advisor warnings (lint 0028 / 0029).

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;

alter function public.is_admin() set schema private;
alter function public.is_company_member(uuid) set schema private;
alter function public.is_applicant_of_my_company(uuid) set schema private;
alter function public.is_resume_shared_with_me(uuid) set schema private;

-- Event-trigger helper created by the "Enable automatic RLS" project option.
-- It only runs as an event trigger, so it never needs to be callable via the API.
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
