# CareerBridge AI

**AI Resume and Career Recommendation System**

[![CI](https://github.com/cheah20/CareerBridgeAI/actions/workflows/ci.yml/badge.svg)](https://github.com/cheah20/CareerBridgeAI/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.14-3776AB?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white)

CareerBridge AI is a web-based career and recruitment platform for job seekers, recruiters and administrators in Malaysia and Singapore. It reads a resume, checks how well it fits a chosen job and experience level, explains the result, and gives short, practical advice on what to do next.

The project is an undergraduate Workshop II project. The AI core (resume reading, career-direction model, fit score and AI advice) works end to end in testing mode; job, application, recruiter and admin features are being built phase by phase.

## Table of Contents

- [Project Overview](#project-overview)
- [Project Objectives](#project-objectives)
- [Target Users](#target-users)
- [Features](#features)
- [Current Development Status](#current-development-status)
- [Technologies Used](#technologies-used)
- [System Architecture](#system-architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Running the Project](#running-the-project)
- [Accessing the Services](#accessing-the-services)
- [Running the Tests](#running-the-tests)
- [Project Directory Structure](#project-directory-structure)
- [Data Kept Locally](#data-kept-locally)
- [Database Information](#database-information)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [Version Control and Collaboration](#version-control-and-collaboration)
- [Development Notes](#development-notes)

## Project Overview

Job seekers often do not know which roles their resume fits, which skills employers expect at each level, or how to improve their chances. Recruiters spend time screening resumes that do not match the job.

CareerBridge AI brings these together in one platform. A job seeker uploads a resume (PDF, Word or a photo); the system reads it, removes personal details, works out a fit score for the chosen job title and level, shows the skill gaps, and suggests career directions. Optional AI coaching adds resume tips, interview practice questions and a learning roadmap. Recruiters and admins get tools to post and review jobs, verify companies, manage applicants and govern the AI models.

AI is used as decision support only. The fit score is a system indicator, not a hiring probability, and it never decides a hiring outcome.

## Project Objectives

1. Help job seekers analyse their resumes, find suitable career directions and jobs, see their skill gaps, and improve their resumes and interview readiness.
2. Help recruiters manage company information, publish jobs, review applicants and their documents with AI-assisted match results, and manage application status.
3. Give administrators tools to govern users, companies, jobs, datasets, AI model versions, system health and bug reports.
4. Compare classic machine learning models (Logistic Regression, KNN, Random Forest, SVM) and a fine-tuned Transformer for career-direction prediction, and deploy the most reliable one.
5. Protect personal data: private file storage, role-based access, and no personal details sent to the AI service.

## Target Users

| User Role | Description |
|---|---|
| Job Seeker | Uploads resumes, sees fit scores, skill gaps, career directions and advice, applies for jobs and tracks applications. |
| Recruiter | Manages company profiles and job posts, reviews applicants and authorised documents, updates application status, arranges interviews. |
| Admin | Verifies companies, reviews jobs, manages users and roles, manages AI models and datasets, monitors errors and usage. Admin accounts are created by the developer only. |

Guests (not logged in) can browse published jobs. Every other feature needs an account.

## Features

### Job Seeker

| Feature | Status |
|---|---|
| Sign-up and login with email confirmation | Done |
| Resume upload: PDF, DOCX, JPG, PNG (up to 10 MB), with OCR for photos and scanned pages | Done (testing mode) |
| AI reading of skills, experience and education, with an "Edit details" page to correct it | Done (testing mode) |
| Fit score for a chosen job title and level, with reasons (e.g. "74% — Good Match") | Done (testing mode) |
| Skill gaps and "what if I add this skill" score preview | Done (testing mode) |
| Career-direction suggestions from the machine learning model | Done (testing mode) |
| AI coach: resume tips, interview questions, learning roadmap | Done (testing mode) |
| Analysis status: Pending, Processing, Completed, Failed | Done (testing mode) |
| Saving resumes and profiles to the account | Planned |
| Job search, filters and recommendations sorted by match | Planned |
| Apply, withdraw and track applications | Planned |

### Recruiter

| Feature | Status |
|---|---|
| Recruiter sign-up and home page | Done |
| Company profile and verification by Admin | Planned |
| Job posting with Admin review | Planned |
| Applicant management with filters and an authorised document viewer | Planned |
| Interview arrangement | Planned |

### Admin

| Feature | Status |
|---|---|
| Admin home page and role-protected access | Done |
| Model version registry: evaluate, deploy, roll back (command line) | Done |
| Admin dashboard: statistics, pending reviews, errors, AI usage | Planned |
| User, role and content management | Planned |
| Bug reports and email notifications | Planned |

### AI and Safety

- Personal details (name, email, phone, IC number, address) are removed before any text reaches the AI service.
- AI answers are cached, every AI request is logged, each user has a daily AI request limit, and the whole system has a monthly limit with alerts at 80% and 100%.
- If the AI service is down, the fit score still works with rule-based scoring.

## Current Development Status

| Component | Current Status |
|---|---|
| Requirements, plan and progress tracker | Done |
| Git and private GitHub repository | Set up |
| Supabase project (database, auth, private storage) | Set up |
| Database schema v1 with Row Level Security | Done; 43/43 permission checks pass |
| FastAPI backend with token and role checks | Done |
| Flutter web app with role-based pages | Done |
| Sign-up and login for all roles | Done; automated end-to-end check 30/30 |
| Resume reading (PDF, DOCX, OCR) | Done |
| Career-direction model (v2 SVM deployed) | Done; 81.5% on the held-out test set, 91–95% on 58 real Malaysian CVs |
| Fit score, skill gaps and AI advice | Working in testing mode |
| Jobs, applications, recruiter and admin features | In progress, phase by phase |
| Cloud deployment | Planned (Week 9) |
| Android APK | Only if time permits |

Week-by-week plan and the progress of every task: [docs/progress.md](docs/progress.md).

## Technologies Used

| Technology | Purpose |
|---|---|
| Flutter 3.47 (Dart) | Web frontend (Android APK later) |
| Riverpod, go_router | App state and page routing |
| Python 3.14 | Backend and machine learning |
| FastAPI | Backend API |
| Supabase PostgreSQL | Database with Row Level Security |
| Supabase Auth | Sign-up, login, email confirmation |
| Supabase Storage | Private resume and company document storage |
| PyMuPDF, python-docx | Reading PDF and Word resumes |
| RapidOCR (ONNX Runtime) | Reading photos and scanned PDFs |
| scikit-learn | Career-direction models (LR, KNN, RF, SVM) |
| DeBERTa-v3-small (ONNX) | Fine-tuned Transformer, compared with the classic models |
| DeepSeek API | Reading resume details and writing advice |
| pytest, flutter_test | Automated tests |
| Git, GitHub | Version control, code review, task board |

Public data used: ResumeAtlas (MIT), Kaggle Resume Dataset (CC0), O\*NET 31.0 (CC BY 4.0), ESCO v1.2.1 and public job-posting sets. LinkedIn and JobStreet are not scraped.

## System Architecture

```text
Flutter web app ──── login, simple reads (protected by RLS) ────► Supabase (Auth, PostgreSQL, Storage)
      │                                                                 ▲
      └──── AI, uploads, business rules (Bearer token) ──► FastAPI ─────┘
                                                              │
                                                              ├── resume reading + OCR
                                                              ├── career model + fit score
                                                              └── DeepSeek API (personal details removed)
```

The Flutter app talks to Supabase directly only for login and simple reads that Row Level Security protects. Everything that needs a secret key, an AI call, a file upload or a business rule goes through the FastAPI backend, which checks the user's role first. Secret keys never reach the browser.

## Prerequisites

> **Teammates making HTML pages in `contrib/`:** you do not need to install anything. Open the `.html` file in Chrome. See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

To run the full app, install:

- **Git**, to download the code and manage changes.
- **Flutter** for Windows: https://docs.flutter.dev/get-started/install/windows
- **Miniconda** for Windows (Python): https://docs.conda.io/en/latest/miniconda.html
- **Google Chrome**, to open the web app.

The owner's Ubuntu (WSL) setup is in [docs/setup-ubuntu.md](docs/setup-ubuntu.md).

## Getting Started

1. Get the code: `git clone https://github.com/cheah20/CareerBridgeAI.git`, or **Code → Download ZIP** on GitHub.
2. Backend, in `ai_backend/` (first time only):

   ```bat
   conda create -n careerbridge-ai python=3.14 -y
   conda activate careerbridge-ai
   python -m pip install -r requirements.txt
   ```

   Copy `.env.example` to `.env` and ask the owner for the values.
3. Frontend, in `frontend/` (first time only): run `flutter pub get`, then copy `config/dev.example.json` to `config/dev.json`.

## Environment Configuration

Secrets live only in local files that Git ignores. The `.example` files are safe templates.

**Backend — `ai_backend/.env`** (from `ai_backend/.env.example`)

| Variable | Purpose |
|---|---|
| `SUPABASE_URL` | Supabase project address |
| `SUPABASE_PUBLISHABLE_KEY` | Public key, protected by Row Level Security |
| `SUPABASE_SECRET_KEY` | Backend-only key. Never share or commit |
| `DEEPSEEK_API_KEY` | AI service key. Backend only. Never share or commit |
| `DEEPSEEK_MODEL` | AI model name |
| `LLM_MONTHLY_BUDGET_USD` | Monthly AI usage limit for the whole system |
| `LLM_DAILY_REQUESTS_PER_USER` | AI requests one user can make per day |
| `TESTING_MODE` | `true` turns on the no-login resume analysis page on this computer. Keep `false` when deployed |

**Frontend — `frontend/config/dev.json`** (from `frontend/config/dev.example.json`)

| Variable | Purpose |
|---|---|
| `SUPABASE_URL` | Same Supabase project address |
| `SUPABASE_PUBLISHABLE_KEY` | Same public key (never the secret key) |
| `API_BASE_URL` | Backend address, `http://localhost:8000` locally |

## Running the Project

| Part | Folder | Start | Stop |
|---|---|---|---|
| Backend | `ai_backend/` (Anaconda Prompt, `conda activate careerbridge-ai`) | `fastapi dev app/main.py` | `Ctrl + C` |
| Frontend | `frontend/` | `flutter run -d chrome --dart-define-from-file=config/dev.json` | `q` |

Start the backend first. Chrome opens the website by itself; press `r` in the frontend window to reload after a change.

**Testing mode:** set `TESTING_MODE=true` in `ai_backend/.env`, restart the backend, then press **Testing mode** on the home page to analyse resumes without logging in. Results stay in `ai_backend/data/logbook/` on this computer.

## Accessing the Services

| Service | Address |
|---|---|
| Web app | Opens in Chrome |
| Backend API | http://localhost:8000 |
| API docs (try every endpoint) | http://localhost:8000/docs |
| Health check | http://localhost:8000/health |

## Running the Tests

| Check | Folder | Command |
|---|---|---|
| Backend unit tests | `ai_backend/` | `python -m pytest` |
| Frontend widget tests | `frontend/` | `flutter test` |
| End-to-end check (backend running) | `ai_backend/` | `python -m tests_e2e.e2e_check` |
| Database permission checks | `supabase/checks/` | See its README |

Test plan and results: [docs/testing/test-plan.md](docs/testing/test-plan.md).

## Project Directory Structure

```text
CareerBridgeAI/
├── frontend/                    # Flutter web app
│   ├── lib/
│   │   ├── app/                 # Theme (colours, fonts), page routes, settings
│   │   ├── core/                # Shared widgets and layout
│   │   └── features/
│   │       ├── public/          # Pages before login, public job list
│   │       ├── auth/            # Login, sign-up, who is logged in
│   │       ├── shell/           # Side menu and frame around every page
│   │       ├── seeker/          # Job Seeker pages
│   │       ├── recruiter/       # Recruiter pages
│   │       ├── admin/           # Admin pages
│   │       └── testing/         # Resume analysis without login (testing mode)
│   ├── test/                    # Widget tests
│   └── config/                  # dev.example.json (copy to dev.json)
│
├── ai_backend/                  # FastAPI backend and AI
│   ├── app/
│   │   ├── api/                 # API endpoints (list in docs/api.md)
│   │   ├── core/                # Settings, token checks, error format
│   │   ├── services/            # Resume reading: PDF, DOCX, OCR, clean text
│   │   ├── matching/            # Fit score rules
│   │   ├── llm/                 # DeepSeek client, personal-data removal, advice
│   │   ├── ml/                  # Career-direction models, evaluation, version registry
│   │   ├── catalog/             # Job titles and skills by level
│   │   └── cli/                 # Terminal tools
│   ├── training/                # Model training scripts
│   ├── tests/                   # Unit tests
│   ├── tests_e2e/               # End-to-end check
│   └── requirements.txt
│
├── supabase/                    # Database migrations and permission checks
├── docs/                        # Requirements, plan, API, database, test plan, AI report
├── contrib/                     # Teammate submissions (HTML pages)
├── .github/                     # Task template for GitHub issues
└── README.md
```

## Data Kept Locally

These stay on the developer's computer only and are not uploaded to GitHub:

| Kept locally | What it is |
|---|---|
| `ai_backend/data/llm/` | Cache and usage log of AI requests |
| `ai_backend/data/logbook/` | Test results from the resume analysis page |
| `ai_backend/data/training_runs/` | Full logs of every model training run |
| `ai_backend/data/raw/`, `eval/`, `synthetic/` | Datasets and test resumes (some contain personal data) |
| `ai_backend/models/` | Trained model files (too big for GitHub) |
| `ai_backend/.env`, `frontend/config/dev.json` | Passwords and keys. **Never upload these** |

Only `ai_backend/data/catalog/` (job titles and skills built from public data) is shared.

## Database Information

The database is Supabase PostgreSQL (Southeast Asia — Singapore). The schema is managed with SQL migrations in [supabase/migrations/](supabase/migrations/).

- **Tables (v1):** profiles, seeker profiles, companies, company members, jobs, resumes, applications, application status history.
- **Access control:** Row Level Security on every table. Each role sees only its own or authorised rows. 43 permission checks pass.
- **Files:** private `resumes` and `company-documents` buckets. Files are opened through the backend, never with public links.
- **Limits:** up to 5 resumes per user, 10 MB per file.

Full table and permission details: [docs/database.md](docs/database.md).

## Documentation

| Document | What it covers |
|---|---|
| [docs/requirements.md](docs/requirements.md) | Agreed scope and requirements |
| [docs/progress.md](docs/progress.md) | Week-by-week plan, decisions, progress of every task |
| [docs/api.md](docs/api.md) | Every backend endpoint with examples |
| [docs/database.md](docs/database.md) | Tables, permissions, storage, local data |
| [docs/testing/test-plan.md](docs/testing/test-plan.md) | Test plan and current results |
| [docs/ml/README.md](docs/ml/README.md) | Model training and evaluation report |
| `docs/report/index.html` | Training report as a web page (download the ZIP and double-click it) |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | How teammates hand in work |

## Troubleshooting

### `conda` is not recognised

Use **Anaconda Prompt** from the Start menu, not the normal Command Prompt.

### The website shows "Server offline · retry"

The backend is not running. Start it (see [Running the Project](#running-the-project)), then press **retry**.

### "Testing mode is off on the server"

Set `TESTING_MODE=true` in `ai_backend/.env` and restart the backend.

### "Cannot reach the CareerBridge server"

Check that the backend window is still open and that `API_BASE_URL` in `frontend/config/dev.json` is `http://localhost:8000`.

### Port 8000 is already in use

Another backend is still running. Close the other window, or start on another port with `fastapi dev app/main.py --port 8001` and change `API_BASE_URL` to match.

### Flutter packages are missing

Run `flutter pub get` in `frontend/`, then start the app again.

### AI tips say they are not available

The AI key may be missing, today's AI requests may be used up, or the AI service may be down. The fit score still works without AI.

## Version Control and Collaboration

- The owner (cheah20) builds the main app. Teammates review work and hand in HTML page designs through `contrib/`.
- Tasks are GitHub issues on the **CareerBridge Tasks** project board. Teammate steps: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).
- Before committing, check `git status` and make sure no `.env`, `dev.json`, datasets or model files are staged.
- Never commit passwords, API keys or real personal data. Test accounts use made-up `@example.test` emails.

## Development Notes

- **Web first:** the desktop web app is built and demoed first. Phone layouts and the Android APK come after the web demo.
- **Testing mode first:** the Job Seeker flow is tuned in testing mode with a local logbook before real accounts and the database are used for it.
- **Open decisions:** final match-level thresholds, whether to deploy the Transformer model, and the hosting provider. See [docs/progress.md](docs/progress.md#open-decisions-tbd--decided-when-the-related-phase-starts).

---

**Project:** CareerBridge AI — AI Resume and Career Recommendation System  
**Project Type:** Undergraduate Workshop II project  
**Development Status:** Foundation and AI core completed; job, application, recruiter and admin features in progress.
