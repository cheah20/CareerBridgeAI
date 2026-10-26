# CareerBridge AI — Test Plan (draft)

Task 7.1. This is the first draft. Each phase adds its test cases here, and the final test report is built
from the "Result" columns.

- **Scope:** [requirements.md](../requirements.md)
- **Last updated:** 2026-10-25

## 1. How we test

| Level | What it checks | Tool | Where | How to run |
|---|---|---|---|---|
| Backend unit tests | Resume reading, scoring rules, AI client limits, API answers | pytest | `ai_backend/tests/` | `python -m pytest` in `ai_backend/` |
| Frontend widget tests | Pages show the right things and buttons do the right thing | flutter test | `frontend/test/` | `flutter test` in `frontend/` |
| Database permission checks | Each role can only see and change what it should (RLS) | SQL script | `supabase/checks/rls_check.sql` | See `supabase/checks/README.md` |
| End-to-end check | Real login → real backend → right home page | Python script | `ai_backend/tests_e2e/e2e_check.py` | [1.6-end-to-end.md](1.6-end-to-end.md) |
| Manual browser checks | What a real user clicks through | Checklist | `docs/testing/*.md` | Follow the checklist, tick each row |
| AI model evaluation | Career-direction model accuracy on held-out and real CVs | Python scripts | `ai_backend/app/ml/` | [ml/README.md](../ml/README.md) |
| User acceptance | Teammates try the demo and report problems | Bug report form (Phase 6) | Hosted demo | Week 9–10 |

Rules for test data: made-up names and `@example.test` emails only. Real CVs are used for model testing only,
with consent, and never uploaded to GitHub.

## 2. Current results

| Check | Result | Date |
|---|---|---|
| Backend unit tests | 103 passed, 3 skipped (skips are "own role" cases in a loop) | 2026-10-25 |
| Frontend widget tests | 35 passed | 2026-10-25 |
| Database permission checks | 43 / 43 passed | 2026-10-15 |
| End-to-end automated check | 30 / 30 passed | 2026-10-18 |
| End-to-end manual checklist | Not done yet (11 steps) | — |
| Career model v2, held-out test set (2,817 resumes, 45 categories) | 81.5% top-1 accuracy | 2026-10-18 |
| Career model v2, 58 real Malaysian CVs | 91–95% (tied with v6–v8) | 2026-10-18 |

## 3. Test cases

Status: `Pass` · `Fail` · `Not run` · `Planned` (feature not built yet)

### A. Roles and permissions

| ID | Case | Expected | How | Status |
|---|---|---|---|---|
| A1 | Call `/me` without a token | 401 | Unit + e2e | Pass |
| A2 | Tampered or expired token | 401 | Unit + e2e | Pass |
| A3 | Job Seeker opens Recruiter / Admin home | 403 | Unit + e2e | Pass |
| A4 | Sign-up tries to choose Admin | Refused; only Job Seeker or Recruiter | RLS check | Pass |
| A5 | Recruiter reads a resume not sent to their company | No rows | RLS check | Pass |
| A6 | Logged-out user opens `/seeker` | Sent to login | Manual | Not run |
| A7 | Testing mode from another computer | 403 | Unit | Pass |
| A8 | Testing mode switched off | Every `/testing` address is 404 | Unit | Pass |

### B. Resume upload and reading

| ID | Case | Expected | How | Status |
|---|---|---|---|---|
| B1 | Upload a text PDF | Text read, sections kept | Unit | Pass |
| B2 | Upload a DOCX | Text read, tables included | Unit | Pass |
| B3 | Upload a JPG / PNG photo of a resume | Read with OCR | Unit | Pass |
| B4 | Scanned PDF (no text layer) | OCR used for those pages | Unit | Pass |
| B5 | Unsupported file (e.g. `.txt`) | Clear message, task shows **Failed** | Unit + live check | Pass |
| B6 | File over 10 MB | Refused with a clear message | Unit | Pass |
| B7 | Name, email, phone, IC number | Removed before the AI sees the text | Unit | Pass |
| B8 | Task status | Pending → Processing (with step) → Completed | Unit + widget | Pass |
| B9 | Store original file in the private bucket | Only owner and allowed recruiters can open it | RLS + unit | Planned (2.1) |
| B10 | 6th resume for the same user | Refused (max 5) | RLS check | Planned (2.1) |

### C. Resume details and profile

| ID | Case | Expected | How | Status |
|---|---|---|---|---|
| C1 | AI reads skills, jobs, education | Shown on the result page | Unit + widget | Pass |
| C2 | User adds a missing skill and saves | Saved, score worked out again | Unit + widget | Pass |
| C3 | User writes a wrong date ("Jan 2023") | Plain message, nothing sent | Widget; server also returns 422 | Pass |
| C4 | Same skill typed twice ("SQL", "sql") | Kept once | Unit | Pass |
| C5 | First reading kept after a correction | `profile_original` unchanged | Unit | Pass |
| C6 | Tips written before a correction | Marked out of date, "Get new tips" offered | Unit + widget | Pass |
| C7 | AI could not read the file | User can type details in and get a full score | Live check | Pass |
| C8 | Profile sync: show differences, user confirms | Only confirmed changes saved | — | Planned (2.5) |

### D. AI: score, model and advice

| ID | Case | Expected | How | Status |
|---|---|---|---|---|
| D1 | Fit score 0–100 with a match level | e.g. "74% — Good Match" | Unit | Pass |
| D2 | Score shown as a fit indicator | Never called a hiring probability | Code review of page text | Pass |
| D3 | "What if I add this skill" | Preview score, not saved | Unit + widget | Pass |
| D4 | AI service down | Score still works (basic mode), friendly message | Unit | Pass |
| D5 | Monthly AI limit at 80% / 100% | Warning logged / non-essential AI paused | Unit | Pass |
| D6 | One user over the daily AI limit | Refused with "reset tomorrow"; other users unaffected | Unit | Pass |
| D7 | Same question asked again | Answer from cache, not counted | Unit | Pass |
| D8 | Career model accuracy | Report the four classic models and the Transformer | Evaluation scripts | Pass |
| D9 | Advice tone | Short, encouraging, never blames the user | Manual review of 10 results | Not run |

### E. Jobs and applications (Phase 4–5)

| ID | Case | Expected | How | Status |
|---|---|---|---|---|
| E1 | Recruiter posts a job | Goes to Admin review, not public yet | Unit + RLS | Planned (4.1) |
| E2 | Admin approves a job | Visible to Job Seekers and guests | Unit + RLS | Planned (4.1) |
| E3 | Search and filter jobs | Correct results, sorted by match | Unit + widget | Planned (4.2) |
| E4 | Apply to a job | One application per job; status history row added | Unit + RLS | Planned (4.3) |
| E5 | Withdraw an application | Status Withdrawn, recruiter sees it | Unit | Planned (4.3) |
| E6 | Status changes (8 statuses) | Each change recorded | RLS (trigger) | Planned (4.4) |
| E7 | Company verification | Unverified company cannot publish | Unit + RLS | Planned (5.1) |

### F. Failure and edge cases

| ID | Case | Expected | How | Status |
|---|---|---|---|---|
| F1 | Backend stopped | Page still loads; "Server offline · retry" | Manual | Not run |
| F2 | Backend restarts during an analysis | Task not found → clear message, result safe in logbook if it finished | Manual | Not run |
| F3 | Blank document (no text at all) | Clear message that no text was found, no crash | Unit | Pass |
| F4 | Unexpected server error | Safe message to the user, details in the server log | Unit (to add) | Not run |

### G. Non-functional

| ID | Case | Target | How | Status |
|---|---|---|---|---|
| G1 | Analysis time (text PDF) | Under 20 s including AI reading | Logbook `timings` | Not run |
| G2 | Secret keys | Never in Git or the frontend | Code review + `.gitignore` | Pass |
| G3 | Personal data in AI requests | None | Unit (B7) | Pass |
| G4 | Desktop web layout at 1280–1920 px | No overlap or cut text | Manual | Not run |

## 4. Still to write

- Test cases for Admin dashboard, model management UI, emails, bug reports and account deletion (Phase 5–6).
- Final test report with screenshots (Week 10).
