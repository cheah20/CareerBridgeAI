# CareerBridge AI

| Folder | Contents |
|---|---|
| `frontend/` | Flutter app (Android + Web) |
| `ai_backend/` | Python AI backend (conda env `careerbridge-ai`) |
| `supabase/migrations/` | Database migrations |
| `docs/` | Project documentation |

## Quick start

```bash
# Frontend
cd frontend
flutter run -d web-server      # then open the printed URL in Windows Chrome

# Backend
conda activate careerbridge-ai
cd ai_backend
```

Never commit `.env` files, Supabase service-role keys, or real resumes.
