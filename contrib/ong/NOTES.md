# Task #__ — page name

**What I made:**
- Built the Admin Company Verification queue page (`index.html`, `style.css`, `script.js`) with summary KPI cards (Waiting, Approved, Rejected, Total).
- Displayed company details (name, SSM registration number, industry, location, contact person/email) and proof documents (`SSM Certificate`, `Utility Bill`, `MIDA License`).
- Added a Document Preview modal when clicking any proof document file.
- Implemented **Approve** and **Reject** actions. Rejecting a company opens a modal requiring a standard category and a mandatory reason note before confirming.
- Created `mock/companies.json` with fallback sample data so the page works both standalone in Chrome and with the #60 FastAPI backend.

**What is not finished / I was unsure about:**
- Currently uses local sample data (`mock/companies.json`). Will connect live `GET /api/companies` and `POST /api/companies/{id}/verify` endpoints in Task #60.
- Some Error handling not complete yet.

**How to look at it:** open `index.html` in Chrome.
