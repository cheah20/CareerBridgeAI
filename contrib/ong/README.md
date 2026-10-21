# Ong — Admin pages

The admin looks after the whole system: users, companies, jobs, the AI model and errors. The admin never decides who gets hired.

## Pages to make

One HTML page per task. The owner will create a task card (#number) for each one on the Projects board.

| # | Page | What it should show |
|---|---|---|
| 1 | Dashboard | Numbers at a glance: users per role, pending company and job reviews, application statuses, current AI model version, recent errors, API usage. A refresh button. |
| 2 | Users and roles | Table of users (name, email, role, status) with search, filter by role, and buttons to disable or change a role. |
| 3 | Company verification | Queue of companies waiting for checking: company details, uploaded proof document, Approve / Reject with a reason. |
| 4 | Job review | Queue of new jobs waiting for approval: job details, Approve / Reject / Ask for changes. |
| 5 | AI model and datasets | List of model versions with accuracy and date, which one is live, buttons for Deploy and Roll back, list of datasets. |
| 6 | Alerts and errors | List of system alerts and errors with time, level and status (open / resolved). |
| 7 | Bug reports | Inbox of bug reports from users: title, who sent it, status, reply box. |

## Before you start

1. Read the admin pages part of [docs/requirements.md](../../docs/requirements.md): sections 2 (Admin), 7 (Admin Features), 16 (Bug reports) and 20 (Logs and monitoring).
2. Copy the [`_starter/`](../_starter/) folder and rename it, for example `ong/12-<short-name>/`.
3. Double-click `index.html` to open it in Chrome. Edit it (VS Code or Notepad), save, press F5.

## Rules for these pages

- Use made-up data only (names like "Example Sdn Bhd", "Aina Example"). **No real people.**
- Keep the colours and fonts from `style.css`. Add new styles at the bottom of the file.
- It only needs to look and click right. Buttons do not have to save anything.
- Write in `NOTES.md` anything you did not finish or were unsure about.
