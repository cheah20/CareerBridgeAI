# Fiqz — Recruiter pages

A recruiter posts jobs for their company and looks at the people who apply. The AI score helps, but the recruiter makes the decision.

## Pages to make

One HTML page per task. The owner will create a task card (#number) for each one on the Projects board.

| # | Page | What it should show |
|---|---|---|
| 1 | Company profile | Company name, logo, industry, size, address, website, verification status (waiting / verified), Edit button. |
| 2 | My job posts | Table of the company's jobs: title, status (draft / waiting review / open / closed), number of applicants, buttons to edit or close. |
| 3 | Create or edit a job | Form: title, description, required skills, experience level, location, work type, salary range, closing date. Save as draft / Submit. |
| 4 | Applicants for a job | List sorted by AI match % (highest first) with filters: status, score range, education, experience, skills. |
| 5 | Applicant detail | The applicant's resume (file viewer area), AI match % with matching and missing skills, and the history of status changes. |
| 6 | Update status and interview | Change status (Applied, Under Review, Shortlisted, Interview, Offer, Hired, Rejected) and a form to set an interview date, time and place. |
| 7 | Contact admin / bug report | A simple form: subject, message, optional screenshot. |

## Before you start

1. Read the recruiter pages part of [docs/requirements.md](../../docs/requirements.md): sections 2 (Recruiter), 6 (Recruiter Features), 8 (Job Posting) and 9 (Application and Interview).
2. Copy the [`_starter/`](../_starter/) folder and rename it, for example `fiqz/12-<short-name>/`.
3. Open `index.html` in Chrome. Edit, save, refresh.

## Rules for these pages

- Use made-up data only (names like "Example Sdn Bhd", "Aina Example"). **No real people.**
- Keep the colours and fonts from `style.css`. Add new styles at the bottom of the file.
- It only needs to look and click right. Buttons do not have to save anything.
- Write in `NOTES.md` anything you did not finish or were unsure about.
