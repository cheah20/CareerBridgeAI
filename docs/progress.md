# CareerBridge AI — Project Plan & Progress Tracker

- **Timeline:** 10 weeks, 2026-10-15 → 2026-12-23
- **Developer:** cheah20 · **Reviewers:** team members (via Pull Requests)
- **Scope reference:** [requirements.md](requirements.md)
- **Review rhythm:** at the end of each week, one Pull Request with that week's work is opened for team review.

**Status:** `Todo` · `In Progress` · `Review` · `Done` · `Blocked`
**Priority:** `P1` must have for the core demo · `P2` required feature · `P3` if time permits

---

## Week overview

| Week | Dates | Phase | Goal / exit criteria | Status |
|---|---|---|---|---|
| 1 | Oct 15 – Oct 21 | 0 + 1 | Setup done; DB schema v1; sign-up / login works for all roles | In Progress |
| 2 | Oct 22 – Oct 28 | 1 | RLS + role permissions verified with test accounts; app shell per role | Todo |
| 3 | Oct 29 – Nov 4 | 2 | Upload PDF/DOCX resume, extract text, show parsed result | Todo |
| 4 | Nov 5 – Nov 11 | 2 | OCR for JPG/PNG; profile sync; dataset selected | Todo |
| 5 | Nov 12 – Nov 18 | 3 | 4 ML models compared; rule-based match score shown | Todo |
| 6 | Nov 19 – Nov 25 | 3 + 4 | LLM explanations/advice; job posting + Admin job review | Todo |
| 7 | Nov 26 – Dec 2 | 4 + 5 | Apply / withdraw / status flow; Recruiter applicant management | Todo |
| 8 | Dec 3 – Dec 9 | 5 | Admin dashboard, company verification, model versions | Todo |
| 9 | Dec 10 – Dec 16 | 6 | Email, bug reports, monitoring, budget alerts; cloud deployment | Todo |
| 10 | Dec 17 – Dec 23 | 7 | Full testing, documentation, demo preparation (buffer week) | Todo |

---

## Task list

### Phase 0 — Preparation

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 0.1 | Save requirements to `docs/requirements.md` | P1 | Oct 15 | — | Done |
| 0.2 | Git identity, first commit, private GitHub repo | P1 | Oct 15 | — | Done |
| 0.3 | Supabase free project (Singapore) + local `.env` | P1 | Oct 15 | — | Done |
| 0.4 | Project plan & progress tracker (this file) | P1 | Oct 15 | — | Done |

### Phase 1 — Foundation (auth, roles, database, RLS)

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 1.1 | Database schema v1 (profiles, roles, companies, jobs, applications, resumes) | P1 | Oct 19 | 0.3 | Done |
| 1.2 | RLS policies + permission tests per role (43/43 pass, `supabase/checks/`) | P1 | Oct 24 | 1.1 | Done |
| 1.3 | FastAPI skeleton: `/health`, Supabase JWT check, role check (15 tests pass) | P1 | Oct 21 | 0.3 | Done |
| 1.4 | Flutter skeleton: routing + role guards, glass theme, role shells, public pages (9 tests pass) | P1 | Oct 21 | — | Done |
| 1.5 | Sign-up / login (Job Seeker, Recruiter); Admin created by system | P1 | Oct 23 | 1.1, 1.4 | Todo |
| 1.6 | End-to-end check: login → correct role home; Flutter ↔ FastAPI | P1 | Oct 28 | 1.2–1.5 | Todo |

### Phase 2 — Resume upload & parsing

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 2.1 | Private storage bucket + upload via FastAPI (type/size validation, 10 MB) | P1 | Nov 1 | 1.6 | Todo |
| 2.2 | PDF / DOCX text extraction → normalized Markdown | P1 | Nov 3 | 2.1 | Todo |
| 2.3 | Structured field extraction + Resume Profile page (view / correct) | P1 | Nov 6 | 2.2 | Todo |
| 2.4 | OCR for JPG / PNG | P2 | Nov 8 | 2.2 | Todo |
| 2.5 | Profile sync: show differences, user confirms updates | P2 | Nov 10 | 2.3 | Todo |
| 2.6 | Background task status (Pending / Processing / Completed / Failed) | P2 | Nov 11 | 2.2 | Todo |

### Phase 3 — AI core

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 3.1 | Select public dataset (check licence) | P1 | Nov 11 | — | Todo |
| 3.2 | Train & compare LR / KNN / RF / SVM (Accuracy, Precision, Recall, F1) | P1 | Nov 16 | 3.1 | Todo |
| 3.3 | Rule-based match score + match levels (e.g. "84% — Strong Match") | P1 | Nov 18 | 2.3 | Todo |
| 3.4 | Choose LLM provider; backend-only key; usage & cost logging | P1 | Nov 20 | — | Todo |
| 3.5 | LLM explanations, skill gaps, resume advice, interview questions, roadmap | P1 | Nov 25 | 3.3, 3.4 | Todo |
| 3.6 | Per-user rate limit + budget alerts (80% / 100%) + no-key mock mode | P2 | Nov 25 | 3.4 | Todo |

### Phase 4 — Jobs & applications

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 4.1 | Job posting form + Admin review for new jobs | P1 | Nov 25 | 1.6 | Todo |
| 4.2 | Job search, filters, recommendations sorted by match | P1 | Nov 28 | 3.3, 4.1 | Todo |
| 4.3 | Apply with resume / supporting documents; withdraw | P1 | Nov 30 | 4.1, 2.1 | Todo |
| 4.4 | Application status tracking (8 statuses + history) | P1 | Dec 2 | 4.3 | Todo |

### Phase 5 — Recruiter & Admin features

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 5.1 | Company profile + Admin company verification | P1 | Dec 1 | 1.6 | Todo |
| 5.2 | Applicant management, filters, authorized document viewer | P1 | Dec 4 | 4.3 | Todo |
| 5.3 | Interview arrangement | P2 | Dec 5 | 4.4 | Todo |
| 5.4 | Admin dashboard (stats, pending reviews, model, errors, API usage) | P1 | Dec 8 | 4.4 | Todo |
| 5.5 | User & role management; job/content governance | P2 | Dec 8 | 1.2 | Todo |
| 5.6 | Model & dataset management: versions, evaluation, deploy, rollback | P1 | Dec 9 | 3.2 | Todo |

### Phase 6 — Notifications, monitoring, operations

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 6.1 | Choose email provider; application / status / interview emails | P2 | Dec 12 | 4.4 | Todo |
| 6.2 | Bug reports (statuses, severity) + Admin email | P2 | Dec 13 | 6.1 | Todo |
| 6.3 | Error logging, alerts, audit logs (90-day retention) | P2 | Dec 14 | — | Todo |
| 6.4 | Backup & recovery approach (check Supabase plan limits) | P2 | Dec 14 | — | Todo |
| 6.5 | Account deletion with 30-day grace period | P3 | Dec 15 | 1.2 | Todo |
| 6.6 | Cloud deployment (frontend + FastAPI) + health checks | P1 | Dec 16 | all P1 | Todo |

### Phase 7 — Testing, documentation, demo

| ID | Task | Priority | Due | Depends on | Status |
|---|---|---|---|---|---|
| 7.1 | Test plan + test report (roles, upload, AI, workflows, failures) | P1 | Dec 20 | 6.6 | Todo |
| 7.2 | Documentation: README, setup, API, DB structure, AI model report | P1 | Dec 21 | — | Todo |
| 7.3 | Demo test accounts, sample data, backup plan | P1 | Dec 22 | 6.6 | Todo |
| 7.4 | Android APK build | P3 | Dec 23 | 6.6 | Todo |

---

## Decisions log

| Date | Decision |
|---|---|
| 2026-10-15 | Architecture B (hybrid): Flutter uses Supabase directly for auth and simple RLS-protected reads; FastAPI handles AI, business rules, permission-sensitive writes, uploads, and all secret keys. |
| 2026-10-15 | Python 3.14 (conda env `careerbridge-ai`); Flutter 3.47 stable; Web first, APK only if time permits. |
| 2026-10-15 | Supabase free plan, region Southeast Asia (Singapore); automatic RLS on, new tables not auto-exposed. |
| 2026-10-15 | Schema v1 applied via Supabase CLI migrations (not the GitHub integration). Admin accounts are created by the developer only. One recruiter may manage several companies. Guests may browse published jobs; every other feature requires an account. |
| 2026-10-15 | Storage budget: keep original files (required for recruiter viewer), store parsed Markdown in the database, OCR images at full quality then compress for storage, max 5 resumes per user. |
| 2026-10-16 | UI style: visionOS-like "Vision Smoke" glass (dark smoke glass, white text) over a blurred office scene; "Vision Ice" light glass as optional mode. Inter font, Material 3 customised, Riverpod, go_router. All design values live in `frontend/lib/app/theme/glass_tokens.dart`. |
| 2026-10-16 | Web first: the desktop web app is built and demoed first. Phone layouts (requirements §21) and the APK are scheduled after the web demo; parked mobile UI lives in `frontend/lib/mobile_ui/`. |
| 2026-10-15 | Secret keys (Supabase secret key, LLM key) live only in backend environment variables, never in Git or the frontend. Team members review code on GitHub and try the system on the hosted demo. |

## Open decisions (TBD — decided when the related phase starts)

| Item | Needed by |
|---|---|
| LLM provider and model | Task 3.4 |
| Public dataset and licence | Task 3.1 |
| Match-level thresholds | Task 3.3 |
| Email provider and sender / Admin address | Task 6.1 |
| Hosting provider and domain | Task 6.6 |

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Large scope for one developer in 10 weeks | High | Build P1 first; week 10 is a buffer; flag delays early in weekly review |
| Supabase free plan limits (backups, project pause after inactivity) | Medium | Check limits in task 6.4; open the project before the demo |
| LLM cost or misuse | Medium | Backend-only key, per-user rate limit, budget alerts, provider spending cap |
| Python 3.14 package compatibility | Low | Check each dependency before installing; separate env if needed |
| OCR quality on image resumes | Medium | Allow manual correction and re-upload (requirement §15) |
