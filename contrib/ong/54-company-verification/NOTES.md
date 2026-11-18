# Task #__ — page name

**What I made:**
- Built the Admin Company Verification queue (`index.html`, `style.css`, `script.js`) with **Interactive KPI Filter Cards** (All submissions, Waiting review, Approved, Rejected):
  - Clicking any of the 4 top KPI cards directly filters the table without needing redundant tab bars.
  - The currently active card is highlighted with a blue border and a `Viewing` badge, paired with a dynamic `Displaying: ...` status indicator badge above the table.
- Added **Search & Numbered Pagination (`‹ Prev | 1 | 2 | 3 | Next ›`)**:
  - Instant search across company ID, name, SSM registration number, location, industry, and contact email (with a quick `✕` clear button).
  - Configurable rows per page (`5`, `10`, `20`) and numbered page buttons to handle hundreds of company records smoothly.
- Added a **Side-by-Side Company Profile & PDF Inspector Modal** (`View Profile & PDF`) to compare submitted company details against real corporate profile PDFs and official SSM e-Info ROC extracts.
- Implemented **Confirmation & Error Handling** for both **Approve** (checkbox confirmation modal) and **Reject** (mandatory reason category + minimum 10-character explanation), plus disabled button states to prevent duplicate clicks.

**What is not finished / I was unsure about:**
- Currently uses `mock/companies.json` (12 sample companies). Will connect to the FastAPI backend endpoints in Task #60.

**How to look at it:** open `index.html` in Chrome.
