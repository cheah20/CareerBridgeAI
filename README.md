# CareerBridge AI

A website that reads a resume, checks how well it fits a job, and gives friendly advice.
Job seekers, recruiters and admins each have their own pages.

**New to this project? Read this page first, then [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).**

## Where to find things

| I want to look at… | Go to | In plain words |
|---|---|---|
| Job Seeker pages | `frontend/lib/features/seeker/` | What a job seeker sees after logging in |
| Resume analysis page | `frontend/lib/features/testing/` | Upload a resume and see the fit score (works without login for now) |
| Recruiter pages | `frontend/lib/features/recruiter/` | What a company recruiter sees |
| Admin pages | `frontend/lib/features/admin/` | What the system admin sees |
| Login and sign-up | `frontend/lib/features/auth/` | Log in, sign up, who is logged in |
| Home page before login | `frontend/lib/features/public/` | The first page visitors see |
| Side menu and page frame | `frontend/lib/features/shell/` | The menu on the left and the frame around every page |
| Colours, fonts, page list | `frontend/lib/app/` | Change the look of the whole website here |
| Reading resumes (PDF, Word, photo) | `ai_backend/app/services/` | Turns a resume file into clean text |
| Fit score rules | `ai_backend/app/matching/` | How the 0–100% score is worked out |
| AI writing (DeepSeek) | `ai_backend/app/llm/` | AI that reads the resume and writes the tips |
| Career direction model | `ai_backend/app/ml/` | Machine learning that guesses a career area |
| Model training scripts | `ai_backend/training/` | Scripts used to train the models |
| Model training records | `docs/ml/` | What was trained, the results and the logs |
| Job titles and skill lists | `ai_backend/app/catalog/` | The list of jobs and skills the system knows |
| Web addresses the app calls | `ai_backend/app/api/` | The backend "doors" the website talks to |
| Database tables and rules | `supabase/` | Where accounts, jobs and applications are stored |
| Automatic checks | `ai_backend/tests/`, `frontend/test/` | Small programs that check nothing is broken |
| Plans and documents | `docs/` | Requirements, progress, reports |
| **Teammate submissions** | `contrib/` | **Put your work here.** The owner reviews it and moves it in |

## What is not on GitHub (on purpose)

These stay on the developer's computer only, so they are not in the ZIP download:

| Kept locally | What it is |
|---|---|
| `ai_backend/data/llm/` | Cache of AI answers, so the same question is not paid for twice |
| `ai_backend/data/logbook/` | Test results from the resume analysis page |
| `ai_backend/data/training_runs/` | Full logs of every model training run |
| `ai_backend/data/raw/`, `eval/`, `synthetic/` | Datasets and test resumes (some contain personal data) |
| `ai_backend/models/` | The trained model files (too big for GitHub) |
| `ai_backend/.env`, `frontend/config/dev.json` | Passwords and keys. **Never upload these.** |

## Run it on your computer

You need: Flutter, and Python through conda. Ask the project owner for the two settings files.

**Backend** (http://localhost:8000/docs)

```bash
conda activate careerbridge-ai
cd ai_backend
fastapi dev app/main.py
```

**Website** (open http://localhost:8080 in Chrome)

```bash
cd frontend
flutter run -d web-server --web-hostname localhost --web-port 8080 --dart-define-from-file=config/dev.json
```

## Run the checks

```bash
cd ai_backend && python -m pytest      # backend
cd frontend && flutter test            # website
```
