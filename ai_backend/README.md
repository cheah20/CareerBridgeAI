# CareerBridge AI — Backend

FastAPI backend for resume processing, AI analysis, and permission-sensitive operations.

## Setup

```bash
conda activate careerbridge-ai          # Python 3.14
cd ai_backend
python -m pip install -r requirements.txt
cp .env.example .env                    # then fill in SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY
```

The env's activate hook hides ROS Noetic's `PYTHONPATH`; it is restored on `conda deactivate`.

## Run

```bash
fastapi dev app/main.py                 # http://localhost:8000/docs (interactive API docs)
```

## Test

```bash
python -m pytest
```

Tests use a locally generated key pair and fake profile data — they never call the real Supabase project.

## Structure

```
app/
├── main.py            # creates the app: CORS, error handlers, routers
├── core/
│   ├── config.py      # settings from environment / .env
│   ├── security.py    # token verification + role checks (dependencies)
│   └── errors.py      # consistent JSON error format
├── api/               # routes (one file per feature)
│   ├── health.py      # GET /health
│   └── users.py       # GET /me
├── schemas/           # request/response models (Pydantic)
├── services/          # business logic (added per feature)
├── models/            # ML models (Phase 3)
└── utils/
tests/
```

## Authentication

The Flutter app logs in with Supabase Auth and sends the access token as `Authorization: Bearer <token>`.

1. `get_current_user` verifies the token with Supabase's **public** signing keys (ES256, JWKS): signature, expiry, audience `authenticated`, and issuer. No secret key is required.
2. It loads the user's `role` and `account_status` from `public.profiles` using the user's own token, so RLS still applies.
3. Inactive accounts get `403`. Missing or invalid tokens get `401`.
4. `require_role(UserRole.ADMIN, ...)` restricts a route to specific roles.

```python
@router.post("/admin/companies/{company_id}/verify")
def verify_company(user: Annotated[CurrentUser, Depends(require_role(UserRole.ADMIN))]):
    ...
```

## Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | Public | Service status |
| GET | `/me` | Logged in | Current user's id, email, role |

## Error format

All errors use one shape:

```json
{ "error": { "code": "unauthorized", "message": "Login required." } }
```

Validation errors (`422`) also include `details` with the field and message.
