# Database checks

## `rls_check.sql` — permission (RLS) test

Creates temporary users (2 Job Seekers, 2 Recruiters, 1 Admin, 1 user who tries to sign up as Admin) and sample companies, jobs, resumes and applications inside one transaction. It then checks what each role and a guest can read or change, and **rolls everything back** — no data is left in the database.

Covers 43 checks: sign-up role rules, Job Seeker / Recruiter / Admin / Guest visibility, blocked direct writes (role change, application status, company verification, job creation), status history, 5-resume limit, 10 MB limit, and duplicate applications.

### Run

From the project root, with the Supabase CLI linked to a project:

```bash
supabase db query --linked -f supabase/checks/rls_check.sql
```

### Read the result

The script reports its result **as an error on purpose** — raising an error is what guarantees the rollback. Ignore `unexpected status 400` and the `--debug` hint, and look for this line:

```
RLS CHECK DONE (rolled back) — 0 failed of 43
```

- `0 failed` → all checks passed.
- Any `FAIL n. ...` line shows which rule broke, with the expected and actual value.

Run it again after every change to RLS policies, grants, or triggers.

### Running it in your own Supabase project (team members)

The main project's keys are not shared. To run the checks yourself:

1. Create a free project at [supabase.com](https://supabase.com) (enable **automatic RLS**, disable **automatically expose new tables**).
2. Install the [Supabase CLI](https://supabase.com/docs/guides/cli), then from the project root:

   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>
   supabase db push          # creates the same schema from supabase/migrations
   supabase db query --linked -f supabase/checks/rls_check.sql
   ```
