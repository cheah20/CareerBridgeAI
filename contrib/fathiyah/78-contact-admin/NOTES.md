
# Task #78 – Contact Admin Page

## What I Made

Created a Contact Admin page for CareerBridgeAI.

The page includes:

- A contact form with a subject field.
- A message field for describing issues.
- An optional screenshot attachment (PNG and JPG).
- Form validation for required fields.
- A submit button with a success message.
- A Previous Reports section showing earlier reports.
- Report statuses: Pending, In Progress and Resolved.
- Example admin responses for previous reports.

## What Is Not Finished

- The form does not connect to a backend.
- Reports are not saved in a database.
- Screenshot files are not uploaded to a server.
- Admin cannot receive or reply to actual reports.
- Previous reports currently use fictional sample data.
- Submitted reports do not appear automatically in the Previous Reports section.

## Data Fields Needed

### Contact Report

- report_id
- user_id
- subject
- message
- screenshot_url (optional)
- submitted_date
- report_status

### Previous Reports

- report_id
- subject
- submitted_date
- report_status
- admin_response
- resolved_date (optional)

## Notes

All sample information is fictional and used for front-end demonstration only.
