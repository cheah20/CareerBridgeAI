# Back end starter

A small FastAPI app that reads and saves a sample JSON file. Copy this whole folder to begin your back end card.

| File | What it is |
|---|---|
| `main.py` | Your endpoints. The job endpoints are examples: change them to the ones on your card |
| `store.py` | Loads and saves `sample_data.json`. You do not need to change it |
| `sample_data.json` | Your made-up data. Replace the example jobs with your own |
| `llm.py` | Optional AI call through OpenRouter. Returns nothing when there is no key |
| `.env.example` | Copy to `.env` only if you use OpenRouter |
| `NOTES.md` | Fill in before you hand in |

## Set up (first time only)

1. Install **Miniconda for Windows**: https://docs.conda.io/en/latest/miniconda.html
2. Open **Anaconda Prompt** from the Start menu, go to your copied folder, and run:

   ```bat
   conda create -n careerbridge-team python=3.12 -y
   conda activate careerbridge-team
   pip install -r requirements.txt
   ```

## Run it

| Start | Stop |
|---|---|
| `fastapi dev main.py` | `Ctrl + C` |

Open http://127.0.0.1:8000/docs. Every endpoint is listed there: press **Try it out**, then **Execute** to test it.

## Add an endpoint

Copy one of the examples in `main.py` and change the path and the data. For example, a list of companies waiting for review:

```python
@app.get("/admin/companies/pending")
def pending_companies():
    return [c for c in store.load()["companies"] if c["status"] == "pending"]
```

Then add a `"companies": [...]` list to `sample_data.json`.

## Using an LLM (optional)

1. Get a free key at https://openrouter.ai/keys.
2. Copy `.env.example` to `.env`, paste the key, and choose a model whose name ends in `:free`.
3. Call `llm.ask("your prompt")`. It returns the answer, or `None` when there is no key or the service fails.

Your code must still work when `llm.ask` returns `None`, for example by using sample text. See `/ai/summary` in `main.py`.

## Rules

- No Supabase and no secret keys. Sample data only.
- **Never upload `.env`.** The repo is public.
- Made-up data only. Never send real people's details to an LLM.

## Hand in

Upload the whole folder (without `.env`) into `contrib/<your name>/`, named `<card number>-api`, with `Closes #<card number>` in the commit box.
