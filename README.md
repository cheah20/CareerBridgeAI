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
| Model training report (web page) | `docs/report/index.html` | Double-click it after unzipping. GitHub shows only the code |
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

## Run it on your computer (Windows)

**Making HTML pages in `contrib/`?** You do not need to install anything. Just open the `.html` file in Chrome.

To run the real app you need two programs. Install them once:

- **Flutter** for Windows: https://docs.flutter.dev/get-started/install/windows
- **Miniconda** for Windows (Python): https://docs.conda.io/en/latest/miniconda.html

The ZIP unzips to a folder named `CareerBridgeAI-main`. The examples below assume it is in `Downloads`.

**1. Backend** (open **Anaconda Prompt** from the Start menu)

```bat
conda create -n careerbridge-ai python=3.14 -y
conda activate careerbridge-ai
cd %USERPROFILE%\Downloads\CareerBridgeAI-main\ai_backend
python -m pip install -r requirements.txt
copy .env.example .env
fastapi dev app\main.py
```

The first four lines are only needed the first time. Ask the owner what to put in `.env`.
Then open http://localhost:8000/docs to check it is running. Keep this window open.

**2. Website** (open a second window: **Command Prompt**)

```bat
cd %USERPROFILE%\Downloads\CareerBridgeAI-main\frontend
copy config\dev.example.json config\dev.json
flutter pub get
flutter run -d chrome --dart-define-from-file=config\dev.json
```

Chrome opens the website by itself. In this window press `r` to reload after a change, `q` to stop.

## Run the checks (Windows)

```bat
cd %USERPROFILE%\Downloads\CareerBridgeAI-main\ai_backend
python -m pytest

cd ..\frontend
flutter test
```

Run the first one in **Anaconda Prompt** (after `conda activate careerbridge-ai`), the second in **Command Prompt**.
