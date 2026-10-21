# AI writing (DeepSeek)

| File | What it is |
|---|---|
| `client.py` | Sends questions to DeepSeek, keeps a cache and a usage limit |
| `profile_extract.py` | AI reads the resume into jobs, skills and education |
| `advice.py` | AI writes the short coach tips |
| `redact.py` | Removes personal details |
| `fill_catalog.py` | AI helps fill in skill lists for rare job titles |

The AI does not learn from our data. The cache of its answers is kept in `ai_backend/data/llm/` on the developer's computer.
