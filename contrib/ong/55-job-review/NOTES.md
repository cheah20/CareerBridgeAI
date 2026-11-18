# Task #__ — page name

**What I made:**
- Built the Admin Job Review queue (`index.html`, `style.css`, `script.js`) displaying newly submitted job postings ranked automatically by AI fraud risk score (**highest risk sorted at the top**).
- Added **Interactive KPI Filter Cards** (`All job posts`, `Waiting review`, `High AI risk ≥ 70%`, `Reviewed jobs`) with active `Viewing` badges, search, risk-tier dropdown, and numbered pagination (`‹ Prev | 1 | 2 | 3 | Next ›`).
- Implemented **Business Logic Rules & Confirmation Modals**:
  1. **Strict Risk Sorting:** Always sorts descending by `riskScore` (`96%` down to `6%`).
  2. **Why `Unverified Company + Low AI Risk` exists (e.g., `JOB-509` BPE Energy at `12% Risk`):** The AI model (#61) evaluates the *job description text* (salary realism, scam keywords), while #54 verifies the *company's SSM documents*. A legitimate newly registered company whose SSM certificate is still `Waiting` in #54 can draft a completely genuine engineering job post (resulting in a Low AI Risk score).
  3. **Dual Approval Safeguard (High-Risk OR Unverified Override):** Clicking **Approve** on a job that is either High Risk (`≥ 70%`) OR from an Unverified Company (`companyVerified: false`) triggers a warning alert inside the confirmation modal requiring an Admin Override / Verification Justification note (min 10 chars) before publishing.
  4. **Mandatory Rejection Reason:** Rejecting a job requires selecting a standard category and entering a detailed explanation.

**What is not finished / I was unsure about:**
- Currently uses sample AI risk scores and trigger keywords in `mock/jobs-review.json`. Will connect to the trained Logistic Regression / Random Forest model from Task #61 and the FastAPI backend in Task #60.

**How to look at it:** open `index.html` in Chrome.
