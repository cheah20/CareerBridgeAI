# CareerBridge AI — Database Structure (v1)

- **Platform:** Supabase PostgreSQL (free plan, Southeast Asia — Singapore)
- **Source of truth:** SQL migrations in [`supabase/migrations/`](../supabase/migrations/)
- **Migrations:**
  - `20261015220000_initial_schema.sql` — tables, triggers, RLS policies, storage buckets
  - `20261015230000_private_rls_helpers.sql` — moves RLS helper functions to the non-exposed `private` schema
- **Scope of v1:** accounts, roles, companies, jobs, resumes, applications. Tables for AI tasks, model versions, LLM usage, interviews, bug reports, emails and audit logs are added in later migrations.

## Entity relationships

```
auth.users (Supabase Auth)
   │ 1:1 (created automatically on sign-up)
   ▼
profiles ──1:1──► seeker_profiles            (Job Seekers only)
   │
   ├──1:N──► resumes                          (Job Seekers)
   │
   └──N:M──► companies  (via company_members) (Recruiters; one recruiter may manage many companies)
                 │
                 └──1:N──► jobs
                              │
                              └──1:N──► applications ◄── resumes (resume used to apply)
                                           │
                                           └──1:N──► application_status_history
```

## Tables

| Table | Purpose | Key columns |
|---|---|---|
| `profiles` | Common data for every user | `id` (= auth user id), `role`, `full_name`, `email`, `phone`, `location`, `account_status`, `deletion_requested_at` |
| `seeker_profiles` | Job Seeker details used for matching | `skills` (text[]), `education` (jsonb list), `experience` (jsonb list), `years_experience`, `headline`, `summary`, `preferred_locations` |
| `companies` | Recruiter companies and verification | `name`, `registration_no`, `industry`, `website`, `location`, `proof_document_path`, `verification_status`, `verified_by`, `verified_at`, `rejection_reason` |
| `company_members` | Which recruiters manage which companies | `company_id`, `user_id`, `member_role` (`owner` / `recruiter`) |
| `jobs` | Job postings (fields from requirements §8) | `title`, `description`, `location`, `work_type`, `work_mode`, `experience_level`, `salary_min`, `salary_max`, `currency` (default `MYR`), `required_skills`, `education_requirement`, `industry`, `vacancy_count`, `application_deadline`, `status`, review fields |
| `resumes` | Resume metadata and parsed content | `storage_path`, `mime_type`, `file_size_bytes` (≤ 10 MB), `parse_status`, `parsed_markdown`, `parsed_data`, `parse_error` |
| `applications` | A Job Seeker applying to a job with a resume | `job_id`, `seeker_id`, `resume_id`, `status`, `match_score` (0–100, fit indicator — not a hiring probability), `applied_at`, `withdrawn_at`; one application per seeker per job |
| `application_status_history` | Every status change, recorded automatically | `from_status`, `to_status`, `changed_by`, `note`, `changed_at` |

### Enumerations

| Type | Values |
|---|---|
| `user_role` | `job_seeker`, `recruiter`, `admin` |
| `account_status` | `active`, `disabled`, `pending_deletion` |
| `verification_status` | `pending`, `verified`, `rejected`, `re_review` |
| `work_type` | `full_time`, `part_time`, `contract`, `internship`, `temporary` |
| `work_mode` | `on_site`, `remote`, `hybrid` |
| `experience_level` | `entry`, `junior`, `mid`, `senior`, `lead` |
| `job_status` | `draft`, `pending_review`, `published`, `rejected`, `closed` |
| `task_status` | `pending`, `processing`, `completed`, `failed` |
| `application_status` | `applied`, `under_review`, `shortlisted`, `interview`, `offer`, `hired`, `rejected`, `withdrawn` |

## Automatic behaviour (triggers)

| Trigger | Behaviour |
|---|---|
| `on_auth_user_created` | On sign-up, creates the `profiles` row (and `seeker_profiles` for Job Seekers). Only `job_seeker` or `recruiter` can be chosen; `admin` is never accepted from sign-up data. |
| `enforce_resume_limit` | A user can keep at most **5 resumes** (free-plan storage budget). |
| `log_application_status` | Writes a history row whenever an application is created or its status changes. |
| `set_updated_at` | Keeps `updated_at` current on every update. |

## Access control

Row Level Security (RLS) is enabled on every table. The frontend uses the public (publishable) key, so RLS decides which rows each user can read.

| Data | Owner | Recruiter | Admin | Guest (not logged in) |
|---|---|---|---|---|
| `profiles` | Read + edit basic fields (not `role` / `account_status`) | Only Job Seekers who applied to their company's jobs | Read all | — |
| `seeker_profiles` | Read + edit | Only applicants to their company's jobs | Via backend only | — |
| `companies` | Members read their companies | Verified companies visible to all logged-in users | Read all | Verified companies, public columns only |
| `jobs` | Company members see drafts | Published jobs visible to all logged-in users | Read all | Published jobs, public columns only |
| `resumes` | Read own | Only resumes submitted to their company's jobs | Via backend only, when necessary | — |
| `applications` | Job Seeker reads own | Applications to their company's jobs | Read all | — |

**Writes with business rules** — publishing/reviewing jobs, verifying companies, uploading resumes, applying, changing application status — are performed by the FastAPI backend, which checks the user's role first. The frontend cannot change these directly.

**RLS helper functions** (`is_admin`, `is_company_member`, `is_applicant_of_my_company`, `is_resume_shared_with_me`) live in the `private` schema, which is not exposed through the Data API, so they cannot be called from the frontend. Supabase security advisors report 0 warnings for this schema.

**Admin accounts** cannot be created through sign-up. A developer creates the user in Supabase and sets `profiles.role = 'admin'`.

**Verification:** [`supabase/checks/rls_check.sql`](../supabase/checks/rls_check.sql) runs 43 permission checks for all roles and guests and rolls back all test data (see [`supabase/checks/README.md`](../supabase/checks/README.md)). Result on 2026-10-15: 43/43 passed. Storage (file) policies are tested in Phase 2.

## File storage

| Bucket | Visibility | Path format | Notes |
|---|---|---|---|
| `resumes` | Private | `<user_id>/<file>` | PDF, DOCX, JPG, PNG, WEBP; ≤ 10 MB. Owners can read their own folder; recruiters get time-limited links from the backend. |
| `company-documents` | Private | `<company_id>/<file>` | Company proof documents; accessed through the backend. |

Storage-saving rules: parsed Markdown is stored in the database (not as files); images are OCR-processed at full quality, then compressed for storage; maximum 5 resumes per user; deleting a resume or account deletes its files.

## Applying migrations

```bash
supabase login                                     # once
supabase link --project-ref <project-ref>          # once, asks for the database password
supabase db push --dry-run                         # preview
supabase db push                                   # apply new migrations
```
