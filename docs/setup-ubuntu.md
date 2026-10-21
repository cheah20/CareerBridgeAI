# Owner setup (Ubuntu / WSL)

For the project owner only. Teammates on Windows: use the main [README](../README.md).

```bash
# backend
conda activate careerbridge-ai
cd ai_backend
python -m pip install -r requirements.txt
cp .env.example .env
fastapi dev app/main.py

# website (second terminal)
cd frontend
flutter run -d web-server --web-hostname localhost --web-port 8080 --dart-define-from-file=config/dev.json

# checks
cd ai_backend && python -m pytest
cd frontend && flutter test
supabase db query --linked -f supabase/checks/rls_check.sql
```
