# AI starter

Every AI card compares **two methods** and reports their scores. This folder gives you a working example to copy.

| File | What it is |
|---|---|
| `compare.py` | Trains two methods on a CSV file, prints both scores, saves `results.json` |
| `metrics.py` | Score functions: classification, skill lists, Precision@5 |
| `example.csv` | 40 made-up job ads labelled `fake` or `real`, only for trying the script |
| `REPORT.md` | Fill in with your results. It becomes your AI section in the final report |

## Set up (first time only)

In **Anaconda Prompt**, with the same environment as your back end:

```bat
conda activate careerbridge-team
pip install -r requirements.txt
```

## Try the example

```bat
python compare.py
```

It prints a table like this, then the words that point most to "fake":

```
Method                  Accuracy  Precision   Recall     F1
Logistic Regression        ...        ...       ...      ...
Random Forest              ...        ...       ...      ...
```

The example is easy, so both methods may score very high. Real datasets are harder, and that is where the comparison gets interesting.

## Make it yours

| Card | What to change |
|---|---|
| Suspicious job detection | Use your dataset in `compare.py`: set `TEXT`, `LABEL` and `POSITIVE` to its columns |
| Skill extraction | Write your two methods as functions that return a skill list per job, then score both with `skill_scores` |
| Talent simulator counts | Count matching profiles two ways and compare the counts against your labelled jobs |
| Job recommendations | Rank jobs for each resume two ways, then score both with `precision_at_k` |
| Resume layout check, digital twin ranking | Compare your two methods against what you marked by hand |

## Rules

- Public datasets only. **Check the licence first** and tell Cheah the name, link and licence.
- Made-up resumes only. Never use real people's resumes.
- If you use an LLM, keep the key in `.env` and never upload it. Your code must still work without it.

## Hand in

Upload your folder into `contrib/<your name>/`, named `<card number>-<short name>`, with `REPORT.md` filled in and `Closes #<card number>` in the commit box. Do not upload big datasets: put a link to them in `REPORT.md` instead.
