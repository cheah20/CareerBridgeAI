# Task #38 — Interview & Status

**What I made:**
- Built the candidate lifecycle management interface for applicant Aina Example applying for "Junior Mobile App Developer".
- Implemented all 7 confirmed application statuses: Applied, Under Review, Shortlisted, Interview, Offer, Hired, and Rejected.
- Implemented the interview scheduling form capturing:
  - Interview Date and Time (MYT)
  - Location / Online Meeting Link (Google Meet or physical office room)
  - Optional Recruiter Notes / Instructions included in the candidate notification email.
- Created dual notification feedback patterns:
  - **Floating Corner Toast Notification**: Triggers for routine updates ("Update Status Only") to inform the recruiter without interrupting workflow.
  - **Centered Modal Dialog**: Triggers for critical actions ("Confirm & Send Invitation") to show clear confirmation of the interview schedule and dispatched email.
- Added clean navigation buttons back to Candidate Detail (`../37-applicant-detail/index.html`) and the Applicants List (`../36-applicants/index.html`).

**What is not finished / I was unsure about:**

**How to look at it:** open `index.html` in Chrome.

# Task #69 — Rejection

- Extended the candidate status management interface so choosing `Rejected` dynamically reveals a required dropdown of 4 fixed rejection reasons (`Missing skill`, `Not enough experience`, `Missing certificate`, `Role filled`) with no free-text input.
- Added client-side validation blocking submission if `Rejected` is selected without choosing a reason.
- Preserved the toast notification for status updates and centered modal confirmation for interview invitations.
