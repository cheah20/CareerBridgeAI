# CareerBridge AI

AI Resume and Career Recommendation System — Flutter web app, FastAPI backend, Supabase (PostgreSQL, Auth, Storage).

| Folder | Contents |
|---|---|
| `frontend/` | Flutter app (web first; mobile UI parked in `lib/mobile_ui/`) |
| `ai_backend/` | Python backend (conda env `careerbridge-ai`) |
| `supabase/` | Database migrations and permission checks |
| `docs/` | Requirements, plan & progress, database structure |

## First-time setup

1. Backend settings: copy `ai_backend/.env.example` to `ai_backend/.env` and fill in the Supabase URL and publishable key.
2. Frontend settings: copy `frontend/config/dev.example.json` to `frontend/config/dev.json` with the same values.
3. Install backend packages: `conda activate careerbridge-ai && python -m pip install -r ai_backend/requirements.txt`

Both settings files are ignored by Git. Never commit secret keys or real resumes.

## Run (two terminals)

**Backend** — http://localhost:8000/docs

```bash
conda activate careerbridge-ai
cd ai_backend
fastapi dev app/main.py
```

**Web app** — open http://localhost:8080 in Chrome

```bash
cd frontend
flutter run -d web-server --web-hostname localhost --web-port 8080 --dart-define-from-file=config/dev.json
```

In the Flutter terminal, press `R` to reload after code changes and `q` to stop.

## Test

```bash
cd ai_backend && python -m pytest                                  # backend
cd frontend && flutter test                                        # frontend
supabase db query --linked -f supabase/checks/rls_check.sql        # database permissions
```
