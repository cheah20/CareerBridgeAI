# How to help (no Git commands needed)

You only need a web browser and your GitHub account. These steps are for Windows.

## 1. Get the latest code

On https://github.com/cheah20/CareerBridgeAI press **Code → Download ZIP**.
In File Explorer, right-click the ZIP → **Extract All**. You get a folder named `CareerBridgeAI-main`.
Do this again whenever you start a new task, so you have the newest version.

(Optional: install **GitHub Desktop for Windows** and use **File → Clone repository**. Then the **Fetch origin** button updates your copy.)

## 2. Pick a task

Open the **Projects** tab and find the board. Each card is one task, with a number like **#12**.

1. Open the card and read: what to do, which files to change, and the due date.
2. Drag the card from **Todo** to **In progress**.

## 3. Do the work on your computer

- **Making a page in HTML?** Copy `contrib/_starter/` and rename the copy, for example `12-admin-dashboard`.
  Double-click `index.html` to open it in Chrome. Edit it in VS Code or Notepad, save, then refresh Chrome (F5). Your task list is in `contrib/<your name>/README.md`.
- **Changing the real app?** Change the files in your unzipped copy and test it (see the main README).

## 4. Hand it in

1. On GitHub, open the `contrib` folder, then your own folder (for example `contrib/ong/`).
   Your folder: Ong → `contrib/ong/`, Fiqz → `contrib/fiqz/`, Fathiyah → `contrib/fathiyah/`.
2. Make the task folder: press **Add file → Create new file** and type `12-admin-dashboard/NOTES.md` as the name.
   Write your notes, then commit. Now the folder exists.
3. Press **Add file → Upload files** and drag in your files (`index.html`, `style.css`, `script.js`, or the app files you changed).
4. Also upload a short `NOTES.md`: what you changed, and how to test it.
5. In the box at the bottom, write the message **`Closes #12`** followed by a short title, for example:

   `Closes #12 Admin dashboard page`

6. Press **Commit changes**.

Because you wrote `Closes #12`, the card moves to **Submitted** by itself. That is how your hand-in is counted.

## 5. After you hand in

The owner checks your files. If they are good, they are moved into the real code and the card goes to **Accepted**.
If something needs fixing, you get a comment on the card.

## Rules

- **Only add files inside `contrib/<your name>/`.** Do not change anything outside it.
- **Never upload real resumes, IC numbers, phone numbers or emails of real people.** Use made-up examples.
- **Never upload `.env`, `dev.json`, passwords or API keys.**
- One task = one folder. Name it `<task number>-<short name>`, for example `12-admin-dashboard`.
