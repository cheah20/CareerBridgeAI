# Task #70: backend API

**Endpoints I made:**

| Method and path | Used by which page | What it does |
- `GET /recruiter/company` & `PUT /recruiter/company`
  - `GET /recruiter/jobs`, `POST /recruiter/jobs`, & `PATCH /recruiter/jobs/{id}`
  - `GET /recruiter/jobs/{id}/applicants` & `GET /recruiter/applications/{id}`
  - `PATCH /recruiter/applications/{id}/status` (enforcing fixed rejection reasons: `Missing skill`, `Not enough experience`, `Missing certificate`, `Role filled`)
  - `POST /recruiter/interviews`
  - `GET /jobs` (open jobs sorted by match %, with location, salary, work type, experience, and industry filters) & `GET /jobs/{id}`

**Database table fields needed (for Supabase tables):**
- `companies`: `id`, `owner_id`, `name`, `industry`, `size`, `address`, `website`, `verification_status`
- `jobs`: `id`, `company_id`, `title`, `description`, `location`, `min_salary`, `max_salary`, `work_type`, `work_mode`, `experience_level`, `industry`, `required_skills`, `vacancy_count`, `closing_date`, `status`
- `applications`: `id`, `job_id`, `candidate_id`, `resume_id`, `match_score`, `matching_skills`, `missing_skills`, `status`, `rejection_reason`
- `application_status_history`: `id`, `application_id`, `from_status`, `to_status`, `changed_by`, `changed_at`
- `interviews`: `id`, `application_id`, `interview_date`, `interview_time`, `location_or_link`, `notes`

**What is not finished / I was unsure about:**

**How to run it:** `fastapi dev main.py`, then open http://127.0.0.1:8000/docs
