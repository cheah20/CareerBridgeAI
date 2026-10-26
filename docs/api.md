# CareerBridge AI — Backend API

The FastAPI backend in [`ai_backend/`](../ai_backend/). While it is running, the full interactive list is at
http://localhost:8000/docs.

- **Base address (local):** `http://localhost:8000`
- **Login:** the website logs in with Supabase Auth and sends the token as `Authorization: Bearer <token>`.
  The backend checks the token and reads the user's role from the database. The role is never taken from the browser.
- **Errors:** every error has the same shape, with a message that is safe to show to users:

```json
{"error": {"code": "bad_request", "message": "Unknown job title."}}
```

| Code | HTTP | When |
|---|---|---|
| `bad_request` | 400 | Wrong choice or file, e.g. unknown job title, unsupported file type |
| `unauthorized` | 401 | No token, expired token or tampered token |
| `forbidden` | 403 | Logged in, but the wrong role for this page; or testing mode used from another computer |
| `not_found` | 404 | Unknown address, logbook entry or task |
| `validation_error` | 422 | A field is missing or in the wrong format. `details` lists each field |
| `service_unavailable` | 503 | The AI service cannot be used right now |
| `internal_error` | 500 | Unexpected problem. Details go to the server log only |

## Main endpoints

| Method | Address | Who | What it does |
|---|---|---|---|
| GET | `/health` | Anyone | Returns `{"status": "ok", "service", "version"}`. Used by the website's "Server connected" chip and by monitoring |
| GET | `/me` | Logged in | Returns `{id, email, role}`. The website calls this after login to open the right home page |
| GET | `/seeker/home` | Job Seeker | Home page data for Job Seekers |
| GET | `/recruiter/home` | Recruiter | Home page data for Recruiters |
| GET | `/admin/home` | Admin | Home page data for Admins |

The three home endpoints return `{role, area, email, server_time}`. Calling another role's home returns 403.

## Testing mode (`/testing/...`)

Resume analysis without login, for building and tuning the Job Seeker flow.

- Only exists when `TESTING_MODE=true` in `ai_backend/.env`. Otherwise every `/testing` address is 404.
- Only answers requests from the same computer (`localhost`). Other computers get 403.
- Results are saved to the local logbook (`ai_backend/data/logbook/`), not to Supabase.

| Method | Address | What it does |
|---|---|---|
| GET | `/testing/catalog` | Fields, job titles and experience levels for the menus |
| POST | `/testing/tasks` | Start an analysis in the background. Returns a task with `status: "pending"` |
| GET | `/testing/tasks/{id}` | Task status (see below). When `completed`, it includes the full result as `entry` |
| POST | `/testing/analyse` | Same analysis, but waits for the result (used by scripts and tests) |
| GET | `/testing/logbook` | Past analyses, newest first (summary only) |
| GET | `/testing/logbook/{id}` | One saved analysis in full |
| PUT | `/testing/logbook/{id}/profile` | Save the Job Seeker's corrections to the details read from the resume, then score again |
| POST | `/testing/logbook/{id}/advice` | Ask the AI coach for tips on a saved analysis |
| POST | `/testing/logbook/{id}/whatif` | Preview the score at another level or with extra skills (not saved) |
| POST | `/testing/logbook/{id}/feedback` | Save a thumbs up / down from the tester |
| GET | `/testing/usage` | AI requests used and left today, and whether the monthly AI limit is close |

### Starting an analysis

`POST /testing/tasks` as `multipart/form-data`:

| Field | Required | Example |
|---|---|---|
| `file` | Yes | PDF, DOCX, JPG or PNG, at most 10 MB |
| `role_id` | Yes | `data-analyst` (from `/testing/catalog`) |
| `level` | Yes | `entry`, `junior`, `mid`, `senior` or `lead` |
| `use_llm` | No | `true` to ask for AI tips after the score (default `false`) |

### Task status

| `status` | Meaning | Extra fields |
|---|---|---|
| `pending` | Received, waiting to start | `step: "Waiting to start"` |
| `processing` | Running | `step`: Reading the file → Reading the details with AI → Scoring the fit → Finding career directions → Saving the result |
| `completed` | Done | `entry_id`, `entry` (the full result) |
| `failed` | Could not finish | `error`: a plain message, e.g. "Unsupported file type. Please upload a PDF, DOCX, JPG or PNG file." |

The website asks for the status once a second. Tasks are kept in memory (the last 50), so restarting the
server clears them; finished results stay in the logbook.

### Correcting the resume details

`PUT /testing/logbook/{id}/profile` with JSON:

```json
{"profile": {
  "headline": "Data Analyst",
  "skills": ["Python", "SQL", "Power BI"],
  "soft_skills": ["Teamwork"],
  "experience": [{"title": "Junior Data Analyst", "organisation": "Example Bank",
                  "start": "2023-01", "end": "present", "type": "full-time"}],
  "education": [{"level": "Bachelor", "field": "Computer Science", "institution": null, "end_year": 2022}],
  "certifications": [],
  "languages": ["English", "Malay"]
}}
```

Rules: dates are `YYYY-MM`, `YYYY` or `present`; job `type` is one of full-time, part-time, internship,
freelance, contract, unknown; education `level` is one of SPM, STPM, Certificate, Diploma, Bachelor, Master,
PhD, Professional, Other. Repeated skills are removed. Wrong formats get a 422 with the field named.

The reply is the whole entry scored again. The first version read from the file is kept as `profile_original`.
If AI tips were already written, `advice_stale` becomes `true` so the page can offer new tips.

### AI request limits

| Limit | Default | What happens |
|---|---|---|
| Per user per day | 30 requests (`LLM_DAILY_REQUESTS_PER_USER`) | Further AI requests are refused with a friendly message. The score still works without AI |
| Whole system per month | Set in `.env` | Warning in the server log at 80%; at 100% only resume reading continues, AI tips pause |

Answers served from the cache do not count. In testing mode every request counts for one local tester.
