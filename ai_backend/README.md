# Backend (Python, FastAPI)

The part that reads resumes, scores them and talks to the AI. The website calls it.

| Folder | What is inside |
|---|---|
| `app/api/` | The "doors" (web addresses) the website calls |
| `app/services/` | Reading resume files: PDF, Word and photos (OCR) |
| `app/matching/` | The fit score rules |
| `app/llm/` | AI writing with DeepSeek: reading the resume, coach tips |
| `app/ml/` | The career direction model (machine learning) |
| `app/catalog/` | Job titles and skill lists, built from public job data |
| `app/core/` | Settings, login checks, error messages |
| `app/schemas/` | The shape of the data sent to the website |
| `app/cli/` | Small tools to run from the terminal |
| `training/` | Scripts used to train the models |
| `tests/` | Automatic checks (`python -m pytest`) |
| `tests_e2e/` | A full check against the real running system |
| `data/` | **On the developer's computer only:** datasets, caches, logs, test results |

## Setup (Windows)

Full steps are in the main [README](../README.md#run-it-on-your-computer-windows). Short version, in **Anaconda Prompt**:

```bat
conda activate careerbridge-ai
cd %USERPROFILE%\Downloads\CareerBridgeAI-main\ai_backend
python -m pip install -r requirements.txt
copy .env.example .env
fastapi dev app\main.py
```

Without an AI key in `.env`, the AI parts are skipped and the simple scoring rules are used.
