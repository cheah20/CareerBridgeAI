# Fathiyah — Job Seeker pages

A job seeker uploads a resume, sees how well they fit jobs, and applies. The resume analysis result page already exists in the app, so these are the other pages around it.

## Pages to make

One HTML page per task. The owner will create a task card (#number) for each one on the Projects board.

| # | Page | What it should show |
|---|---|---|
| 1 | Home | Welcome, latest match score, number of applications, top 3 recommended jobs, a button to upload a resume. |
| 2 | My resume profile | What the system read from the resume: work, education, skills, languages. Each part can be corrected with an Edit button. |
| 3 | Recommended jobs | Job list sorted by match % (highest first) with filters: location, salary range, work type, experience level, industry. |
| 4 | Job detail | Job description, company, the match % with matching and missing skills, and an Apply button. |
| 5 | My applications | Table of applications: job, company, date, status (Applied … Hired / Rejected / Withdrawn), and a Withdraw button where allowed. |
| 6 | Interview practice and roadmap | Practice questions with tips, and a learning roadmap: steps with weeks. |
| 7 | Contact admin / bug report | A simple form: subject, message, optional screenshot. |

## Before you start

1. Read the job seeker pages part of [docs/requirements.md](../../docs/requirements.md): sections 2 (Job Seeker), 5 (Job Seeker Features), 9 (Applications) and 10 (Profile sync).
2. Copy the [`_starter/`](../_starter/) folder and rename it, for example `fathiyah/12-<short-name>/`.
3. Double-click `index.html` to open it in Chrome. Edit it (VS Code or Notepad), save, press F5.

## Rules for these pages

- Use made-up data only (names like "Example Sdn Bhd", "Aina Example"). **No real people.**
- Keep the colours and fonts from `style.css`. Add new styles at the bottom of the file.
- It only needs to look and click right. Buttons do not have to save anything.
- Write in `NOTES.md` anything you did not finish or were unsure about.
