# Task #__ — page name

**What I made:**
- Built the Admin AI Models & Datasets management page (`index.html`, `style.css`, `script.js`) listing all model versions, evaluation metrics (`Accuracy`, `Precision`, `Recall`, `F1 Score`), trained dates, and active production statuses.
- Added **Interactive KPI Filter Cards** (`Total Model Versions`, `Active (In Use)`, `Job Fraud Models (#61)`, `Standby / Rollback Ready`) with `Viewing` badges, pipeline filter, search bar, and numbered pagination (`‹ Prev | 1 | 2 | Next ›`).
- Implemented **Deploy / Roll Back Business Logic & Confirmation Modals**:
  1. **Single Active Model per Pipeline:** Promoting or rolling back a version in `Suspicious Job Detection`, `Resume Layout Check`, or `Resume-Role Fit Scoring` automatically switches the previously active model in that pipeline to `Standby`.
  2. **Side-by-Side Metric Delta & Regression Warning:** Clicking **Deploy** or **Roll back** opens a confirmation modal comparing the current active model against the target version (`±% Accuracy`). Rolling back or switching to a lower-accuracy version requires a mandatory justification note (min 10 chars).
  3. **Model Details Inspector:** Clicking any model opens a breakdown of its 4 benchmark metrics and top learned features.
- Added the **Training & Evaluation Datasets Registry** table documenting EMSCAD (`CC0 Public Domain` for #61), the 10 Synthetic Layout PDFs (#62), and the Malaysian Roles catalog.

**What is not finished / I was unsure about:**
- Currently loads from `mock/models-datasets.json` (with local fallback). Will connect to the FastAPI backend in Task #60 and update the exact final metrics once Task #61 training is finalized.
**How to look at it:** open `index.html` in Chrome.
