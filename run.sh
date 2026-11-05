#!/usr/bin/env bash
# starts the backend and the web app together, open http://localhost:8080
root="$(cd "$(dirname "$0")" && pwd)"

eval "$(conda shell.bash hook)"
conda activate careerbridge-ai || exit 1

# stop the backend when the web app quits
trap 'kill $api 2>/dev/null' EXIT

cd "$root/ai_backend" && fastapi dev app/main.py &
api=$!

cd "$root/frontend" && flutter run -d web-server --web-port 8080 --dart-define-from-file=config/dev.json
