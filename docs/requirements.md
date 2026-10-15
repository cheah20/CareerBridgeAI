# CareerBridge AI --- Project Requirements & Implementation Specification

> **Official project title:** AI Resume and Career Recommendation
> System\
> **Product / UI name:** CareerBridge AI\
> **Document status:** Requirements confirmed through Item 50\
> **Purpose:** Consolidated implementation reference for development,
> testing, deployment, and final demonstration.\
> **Rule:** Details that have not been confirmed are marked **TBD**
> rather than assumed.

------------------------------------------------------------------------

## 1. Project Overview and Objectives

CareerBridge AI is an AI-assisted career recommendation and recruitment
platform for **Job Seekers**, **Recruiters**, and **Admins**.

### Main objectives

-   Help Job Seekers analyze resumes, explore suitable career directions
    and specific job openings, identify skill gaps, improve resumes,
    prepare for interviews, and follow learning roadmaps.
-   Help Recruiters manage company information, publish jobs, review
    applicants and supporting documents, view AI-assisted job-match
    results, and manage application statuses.
-   Give Admins tools to govern users, companies, jobs, system
    operations, datasets, AI models, model evaluation, alerts, and bug
    reports.
-   Use AI as decision support. AI match scores are not hiring
    probabilities and must not automatically determine hiring outcomes.

## 2. User Roles and Responsibilities

### Job Seeker

-   Manage profile and resumes.
-   Upload and analyze resumes.
-   View career directions, job recommendations, match explanations,
    skill gaps, improvement advice, interview preparation, and learning
    roadmaps.
-   Apply for jobs, track applications, and withdraw eligible
    applications.
-   Submit bug reports and contact Admin.

### Recruiter

-   Manage company profile and job postings.
-   Manage applicants and view authorized resumes/supporting documents.
-   Review AI job-match results and independently make recruitment
    decisions.
-   Update application statuses and arrange interviews.
-   Submit bug reports and contact Admin.

### Admin

-   Manage users, roles, permissions, companies, jobs, and content
    governance.
-   Verify companies and review jobs according to the configured rules.
-   Manage datasets, model versions, training/evaluation, deployment,
    and rollback.
-   Monitor system status, errors, API usage, and bug reports.
-   Receive bug-report and critical-system notifications.
-   Admin does **not** make hiring decisions on behalf of Recruiters or
    the AI system.
-   Resume content is accessed only when necessary for legitimate
    administration; an Admin role does not imply unrestricted casual
    access to private content.

## 3. Confirmed Technology Stack

  -----------------------------------------------------------------------
  Layer                               Confirmed choice
  ----------------------------------- -----------------------------------
  Frontend                            Flutter + Dart

  Initial frontend target             Responsive Web first

  Android                             Android APK if time permits

  Backend API                         Python + FastAPI

  Database                            Supabase PostgreSQL

  Authentication                      Supabase Auth

  Private file storage                Supabase Storage

  ML training/evaluation              Local development computer

  LLM                                 One fixed API provider;
                                      provider/model is TBD

  AI strategy                         Hybrid: local ML
                                      training/evaluation and deployed
                                      inference; LLM API for explanations
                                      and generated advice, with
                                      local-model fallback if available
  -----------------------------------------------------------------------

The Web application is the first delivery priority. The Android APK is
conditional on available time and is not a prerequisite for completing
the Web version.

## 4. Core AI Design and Processing Pipeline

### Resume processing pipeline

1.  User uploads a supported resume file.
2.  A parser/OCR process extracts text.
3.  Convert extracted content into a normalized Markdown (`.md`)
    representation for LLM context.
4.  Preserve important facts, remove duplicate or irrelevant text where
    appropriate, and mark uncertain or missing information rather than
    inventing it.
5.  Save structured fields to the database and retain the original
    source file according to storage/privacy rules.
6.  Run ML classification and rule-based matching as appropriate.
7.  Use the LLM to explain results and generate recommendations,
    improvement suggestions, interview questions, and related advice.
8.  Display successful outputs even if a nonessential part of the
    analysis fails.

**Important:** Markdown conversion alone does not guarantee lower token
usage. Token savings come from deduplication, removing irrelevant
content, and sending only the context required for each task.

### ML model comparison

Compare the following candidate algorithms: - Logistic Regression -
K-Nearest Neighbors (KNN) - Random Forest - Support Vector Machine (SVM)

Select a model based on recorded experimental results rather than
assuming a winner in advance.

### Evaluation metrics

-   Accuracy
-   Precision
-   Recall
-   F1-score

The evaluation report must identify the model version, dataset version,
training time, deployment status, and comparison with the previous
model.

### Responsibilities of each AI component

-   **ML:** classify career/job direction and support model-based
    predictions.
-   **Rule-based matching:** compare candidate skills, education,
    experience, and other relevant fields with job requirements to
    calculate a system-defined match score.
-   **LLM:** explain strengths and gaps and generate advice, interview
    questions, and other confirmed guidance.
-   The LLM must not invent ML evaluation metrics or present the match
    score as the probability of getting hired.

## 5. Job Seeker Features

All of the following are confirmed core features: 1. **Resume Profile:**
extract, display, and allow correction of resume information. 2.
**Career and Job Recommendations:** recommend career directions and
specific company job openings. 3. **Skill Gap and Improvement:**
identify missing or weakly evidenced skills and suggest improvements. 4.
**Interview Preparation:** generate relevant interview questions and
preparation suggestions. 5. **Personalized Learning Roadmap:** provide a
learning roadmap based on career goals and gaps. 6. **Resume
Improvement:** provide suggestions to improve resume content and
presentation.

### Job recommendations and filters

-   Default sort: AI Match Percentage, highest first.
-   Filters: location, salary range, work type, experience level, and
    industry.
-   Recommend both career directions and available jobs within
    CareerBridge AI.
-   External job-board APIs are not a core requirement.

### Match results

Display: - Overall match percentage and a text level, such as
`84% — Strong Match`. - Matching skills. - Missing skills. - Education
and experience fit. - Improvement suggestions and reasons. - If
information is insufficient, explain what is missing and how it affects
the result, and ask the user to add information where useful.

Match-level thresholds are **TBD** and must be defined consistently in
the implementation. A match percentage indicates system-defined fit, not
hiring probability.

## 6. Recruiter Features

All of the following are confirmed core features: 1. Company Profile. 2.
Job Posting Management. 3. Applicant Management. 4. Resume and
Supporting Document Viewer. 5. AI Job Match Results. 6. Application
Status Management. 7. Bug Report / Contact Admin.

### Applicant management

-   Default sort: AI Match Percentage, highest first.
-   Filters: application status, match-score range, education, work
    experience, and skills.
-   Recruiters review candidate data and make their own decisions.
-   Do not automatically reject candidates solely because of an AI match
    score.

### Application statuses

Supported statuses: - `Applied` - `Under Review` - `Shortlisted` -
`Interview` - `Offer` - `Hired` - `Rejected` - `Withdrawn`

Retain application history including job, company, application date, and
final status.

## 7. Admin Features

All of the following are confirmed core features: 1. System Overview
Dashboard. 2. User & Role Management. 3. Company Verification. 4. Job &
Content Governance. 5. AI Model & Dataset Management. 6. Model
Evaluation Metrics. 7. System Alerts & Error Monitoring. 8. Bug Reports
& Email Notifications.

### Admin dashboard

Show an overview of: - Basic system statistics and user-role
distribution. - Pending company and job reviews. - Application-status
distribution. - Current AI model version and latest evaluation. - System
errors and API usage.

Dashboard supports scheduled automatic refresh and manual refresh.

### Company and job governance

-   Admin manually reviews company information and proof documents.
-   Unverified companies may complete profiles and create job drafts,
    but may not publicly post jobs or view private candidate resumes.
-   New jobs require Admin review.
-   Subsequent jobs from verified companies may publish directly
    according to configured rules.
-   Major changes to company information trigger re-review and may
    temporarily restrict posting.
-   When a job is closed, stop accepting new applications while
    retaining the job and its historical applications.

### Admin AI governance

-   Manage datasets, model training/evaluation, model versions,
    deployment, and rollback.
-   Admin can review alerts and resolve issues.
-   AI governance does not mean Admin decides who should be hired.

## 8. Job Posting Requirements

The job form includes: - Job title - Company - Location - Job
description - Work type - Application deadline - Salary range -
Experience level - Required skills - Education requirements - Work
mode - Vacancy count

Company verification and job publishing rules are described in Section
7.

## 9. Application and Interview Workflow

-   Job Seekers apply using a previously uploaded and authorized resume.
-   Supporting documents may be selected according to the job
    requirements.
-   Recruiters manage applications and update statuses.
-   Job Seekers track status through the Dashboard/Application Tracking
    area.
-   Job Seekers may withdraw an application that has not ended; set the
    status to `Withdrawn` and notify the Recruiter.
-   Recruiters arrange interviews within the system.
-   Send email notices for interview arrangements and application-status
    changes.
-   Do not expose a resume or supporting document to a Recruiter unless
    the Job Seeker has applied for that job or explicitly authorized
    access.

## 10. Profile and Resume Synchronization

-   After parsing a resume, show the extracted fields and let the Job
    Seeker confirm which profile fields to update.
-   If parsed resume data conflicts with existing profile data,
    prioritize user-confirmed profile information by default.
-   Clearly identify differences and allow the user to decide whether to
    update fields.

## 11. Resume Upload and Storage

Supported file types: - PDF - DOCX - JPG - PNG

Limit: - Maximum 10 MB per file.

Users may keep multiple resumes and delete older ones.

Store: - Original file in private file storage. - Parsed Markdown
representation and structured analysis data as appropriate. - Metadata
and file references in PostgreSQL.

Users may delete their own resumes and associated analysis records.
Storage and database access must be protected by the appropriate
authorization rules.

## 12. Database, Authentication, and Access Control

-   Use Supabase Auth for authentication.
-   Use PostgreSQL roles and Row Level Security (RLS).
-   Use Supabase Storage for files; PostgreSQL stores file references
    and metadata.
-   Configure file-storage access controls as well as database policies.
-   Recruiters can access a resume/supporting document only after the
    Job Seeker applies to the relevant job or explicitly authorizes
    access.
-   Admin accesses private resume content only when necessary.
-   Backend must validate the user's role; hiding a control in the
    frontend is not sufficient.
-   Job Seekers can delete their own resumes and related analysis
    records.
-   Keep private resume files out of public URLs.

The exact database schema, table names, RLS policies, and retention
implementation are **TBD** and must be documented during implementation.

## 13. LLM API, Local Fallback, and Budget Controls

-   Use one fixed LLM API provider; exact provider/model is **TBD**.
-   Track API usage and estimated cost.
-   Set token/context limits and avoid duplicate API calls.
-   If the API is unavailable or the budget is too low, try a local
    model first if available.
-   If both API and local model are unavailable, notify the user and
    preserve core functionality that does not depend on the unavailable
    model.
-   At 80% of the configured budget, alert Admin.
-   At 100%, notify Admin and limit nonessential LLM requests.
-   Maintain per-request logs with timestamp, model, token counts,
    estimated cost, request status, and error details.
-   Do not expose API keys or other secrets to the frontend.

## 14. Model Training, Versioning, Deployment, and Rollback

### Training and evaluation

-   Support Admin-triggered manual training and optional automatic
    training/updates.
-   Primarily use public datasets for training and evaluation.
-   Compare Logistic Regression, KNN, Random Forest, and SVM with
    Accuracy, Precision, Recall, and F1-score.
-   Evaluate a new model before deployment; do not immediately overwrite
    the current model.
-   Deploy based on predefined evaluation criteria or Admin
    confirmation.
-   Keep previous versions available for comparison and rollback.

### Versioning

Track: - Model version. - Associated dataset version. - Evaluation
results. - Training time. - Deployment status.

### Deployment and rollback

-   Hybrid control: Admin can deploy manually; a model meeting
    predefined criteria may deploy automatically.
-   Hybrid rollback: automatic rollback under predefined rules plus
    Admin-initiated manual rollback.
-   Record model deployment and rollback operations.
-   Detailed acceptance thresholds and automatic deployment/rollback
    triggers are **TBD**.

## 15. Failure Handling and Long-Running Tasks

### Parsing failure

-   Allow the user to re-upload the file or enter information manually.

### AI service failure

-   Try the local fallback model if available.
-   If unavailable, notify the user and retain non-AI-dependent
    functionality.

### Partial analysis failure

-   Show successfully completed outputs.
-   Clearly mark failed parts rather than hiding all results.

### Background tasks

-   Ordinary requests may be handled directly.
-   Long resume parsing, AI analysis, and model-related tasks run as
    background jobs.
-   Task statuses: `Pending`, `Processing`, `Completed`, `Failed`.
-   Limit concurrent AI tasks.
-   If the queue becomes too long, pause accepting new long tasks.
-   Retry transient failures a finite number of times and display the
    task status.

## 16. Email Notifications and Bug Reports

### Required email types

-   Application submission confirmation.
-   Application status update.
-   Interview arrangement notice.
-   Bug report notification to Admin.

### Bug report workflow

-   Job Seekers and Recruiters can submit bug reports through their
    respective interfaces.
-   Save reports in the database and email Admin's official address.
-   Admin can view reports and update their status.
-   Reporter can see status in the system and receives email updates.

Bug report statuses: - `New` - `Under Review` - `In Progress` -
`Resolved` - `Closed` - `Rejected`

Admin assigns severity: - `Low` - `Medium` - `High` - `Critical`

Email provider, sender address, and Admin's official email address are
**TBD**. Email failures should be logged and retried where appropriate.

## 17. Security Requirements

All of the following are mandatory: - PostgreSQL RLS limits users to
authorized data. - Private resume files have controlled access and no
public URLs. - Backend validates Job Seeker, Recruiter, and Admin
permissions. - Store LLM API keys and email credentials in backend
environment variables or a secret-management service. - Validate upload
file type, file size, and form inputs. - Log important Admin operations,
including company verification, job governance, and model-version
changes. - Do not log passwords, API keys, or unnecessary resume
content.

## 18. Account and Personal Data Lifecycle

Confirmed approach: - After a user confirms account deletion, disable
the account and begin a **30-day grace period**. - The user can request
cancellation during the grace period. - After 30 days, delete or
anonymize personal data. - Delete resume files, parsed resume results,
and personal AI analysis. - For submitted applications, delete or
anonymize personal identifiers while retaining necessary application
records. - Records required for legal, compliance, or audit purposes may
be retained as appropriate. - Restore/cancellation mechanics during the
grace period must be defined during implementation.

## 19. Backup and Recovery

-   Perform database backups daily.
-   Retain backups for 30 days.
-   Use hybrid recovery: automatic recovery when severe faults meet
    predefined conditions, plus Admin-controlled manual recovery.
-   Log recovery operations.
-   Confirm that the selected Supabase plan and hosting arrangement
    support the intended backup and recovery behavior; actual capability
    depends on the selected plan and deployment.

## 20. System Logs, Audit, and Monitoring

### Log events

-   Authentication/login events.
-   Key user actions.
-   Job and application status changes.
-   Company reviews.
-   Permission changes.
-   AI model deployment and rollback.
-   Errors.
-   Data recovery operations.

### Retention and access

-   Retain logs for 90 days.
-   Admin can view system/audit logs.
-   Developers may view technical error logs only when authorized.
-   Job Seekers and Recruiters cannot view internal system logs.
-   Avoid logging passwords, API keys, and unnecessary resume content.

### Alerts

-   Backend logs exceptions.
-   Important exceptions, especially Critical ones, trigger email
    notifications to Admin.
-   System errors and API usage are visible in the Admin dashboard.

## 21. Performance and User Experience

### Accessibility and responsive design

-   Responsive Web layout for desktop, tablet, and mobile browsers.
-   Layout adapts to screen size.
-   Clear form labels and operation guidance.
-   Keyboard-operable controls.
-   Appropriate text/background contrast.
-   Necessary text descriptions for images and icons.

### Loading and waiting experience

-   Ordinary operations show a loading state.
-   Long-running tasks show progress or task status.
-   Timeout and failure messages are clear and provide a retry option.

### Concurrency and load protection

-   Design/test target: **20 concurrent users**; this is a target, not a
    performance guarantee.
-   Handle long-running AI work in a background queue.
-   Limit concurrent AI tasks and pause new long tasks when the queue is
    too long.
-   Use finite retries for transient failures and display task status.

### UI language and style

-   Entire interface in English.
-   Professional, clean, comfortable recruitment-platform style.
-   Avoid excessive decoration and AI illustrations.
-   Normal users see understandable results, match reasons, and
    suggestions.
-   Technical metrics are shown in Admin pages, not exposed without
    explanation to ordinary users.
-   Exact colors, fonts, and component library are **TBD**.

## 22. API Usage and Budget Monitoring

Admin monitoring must include: - Cumulative API usage. - Estimated costs
and remaining budget. - Daily usage. - Per-model usage. - Token
consumption. - Error counts. - Cost trends. - Per-request logs:
timestamp, model, token counts, estimated cost, request status, and
error details.

Budget alert policy: - 80%: alert Admin. - 100%: notify Admin and limit
nonessential LLM requests.

The actual budget amount and provider pricing are **TBD**.

## 23. Supabase and Hosting Considerations

-   Begin with free services where practical.
-   When limits are reached, optimize code and resource usage first;
    Admin decides whether to upgrade.
-   Supabase Storage holds original resume files; PostgreSQL holds
    metadata, references, and structured records.
-   Avoid unnecessary duplicate Markdown and analysis data; limit file
    size and provide deletion.
-   Keep model files and training datasets local or in an appropriate
    separate storage location where suitable.
-   Free-tier quotas and features may change and must be checked before
    deployment. The free tier may not be sufficient for long-term
    production usage.
-   Web frontend and FastAPI backend are deployed to the cloud.
-   Local computer is used for ML training/evaluation; the resulting
    model is saved and deployed or served for inference.
-   Hosting provider, GPU/resource requirements, deployment cost, and
    production service limits are **TBD**.

## 24. Deployment and Release Management

-   Prioritize free/low-cost hosting.
-   Monitor critical services.
-   Record faults and notify Admin.
-   Retry recoverable temporary faults a finite number of times; show a
    clear failure state if retries fail.
-   Keep the last stable version.
-   After deployment, run health checks and basic tests.
-   For severe faults, use automatic rollback or rollback by an
    authorized person.
-   Log release version and deployment/rollback operations.
-   Deployment provider, domain, and detailed release configuration are
    **TBD**.

## 25. Testing and Acceptance

### Test coverage

Test all confirmed core features, including: - Role permissions. -
Resume upload and parsing. - AI classification and recommendations. -
Job matching and explanations. - Job posting and application
workflows. - Email notifications. - Bug reports. - Model/dataset
management and evaluation. - Backup and recovery. - Exception and
failure handling.

### Test data

Use: - Test accounts for different roles. - Resume samples with
different formats and content. - Different job requirements. - Simulated
application data. - Normal workflows, invalid inputs, and common errors.

### Defect handling

Classify defects as: - `Critical` - `High` - `Medium` - `Low`

Record reproduction steps, impact, owner, status, and fix result.
Prioritize serious defects.

### Acceptance criteria

-   All confirmed core features work.
-   Permissions for all three roles are correct.
-   Resume analysis, job matching, applications, and key notifications
    pass testing.
-   No unresolved Critical or High severity defects.
-   Other known issues are documented with their impact and a resolution
    plan.
-   Project documentation and deliverables are complete.

## 26. Code Quality and Team Collaboration

### Code quality

-   Split code into modules by feature/responsibility.
-   Use consistent naming and formatting.
-   Handle exceptions.
-   Write necessary tests for core AI, API, and business logic.

### Git and GitHub

-   Use GitHub to manage source code.
-   Use feature branches.
-   Write clear Commit messages.
-   Use Pull Requests or code review.
-   Configure `.gitignore` to prevent API keys, passwords, and sensitive
    configuration from being committed.

CI automation, GitHub Actions, and release automation were not selected
as mandatory requirements.

## 27. Project Documentation and Deliverables

### Required documentation

-   README.
-   Environment configuration.
-   Installation and deployment steps.
-   API documentation.
-   Database structure.
-   AI model and dataset explanation.
-   Common errors and troubleshooting.

### Confirmed deliverables

-   Runnable Web system.
-   Complete source code.
-   Database configuration and structure.
-   AI model and evaluation report.
-   Technical project documentation.
-   Test report.

The Android APK is conditional on development time. It is not a
mandatory deliverable under the selected delivery scope.

## 28. Final Demonstration

Demonstrate the main workflows for all three roles: - Job Seeker: resume
analysis and recommendations. - Job Seeker/Recruiter: job matching and
application management. - Recruiter: applicant review and status
management. - Admin: AI model evaluation and relevant governance
functions.

Prepare backup test accounts and data in case of live-demo issues.

## 29. Project Scope and Progress Management

### Scope changes

-   Preserve all confirmed core features.
-   Evaluate time, budget, and technical impact before accepting new
    features.
-   Adjust development order when needed.
-   Do not casually remove confirmed requirements.

### Progress tracking

Break the project into phases and tasks. Record: - Owner. - Priority. -
Due date. - Progress. - Dependencies.

Review risks and delays regularly.

### Suggested implementation order

1.  Project foundation, authentication, roles, database, and RLS.
2.  Resume upload, parsing, Markdown normalization, and profile
    synchronization.
3.  ML classification, rule-based matching, and match explanations.
4.  Internal job posting, application flow, and status tracking.
5.  Recruiter and Admin features.
6.  Email notifications, bug reports, model governance, monitoring,
    backup/recovery.
7.  Testing, documentation, deployment, and final demonstration.

This order prioritizes delivery sequencing; it does not remove any
confirmed core feature.

## 30. Unconfirmed Details (TBD)

The following details were not confirmed and must not be silently
assumed: - LLM API provider and exact model. - Email provider, sender
address, and Admin official email address. - Cloud hosting provider,
domain, compute/GPU resources, and final operating costs. - Exact
database schema/table names and implementation-level RLS policies. -
Match-score category thresholds. - Model evaluation thresholds for
automatic deployment and rollback. - Exact retry counts/timeouts and
background queue implementation. - Exact UI colors, fonts, and component
library. - Detailed account-restoration process during the 30-day
deletion grace period. - Production backup/restore capabilities
available under the selected hosting and Supabase plan. - Final public
dataset choices and dataset licenses. - Any production privacy/legal
retention rules that require validation before launch.

## 31. Non-Negotiable Principles

1.  The product is **CareerBridge AI**, officially titled **AI Resume
    and Career Recommendation System**.
2.  The three roles are Job Seeker, Recruiter, and Admin.
3.  All confirmed core features remain in scope.
4.  AI match scores are fit indicators, not hiring probabilities.
5.  AI is decision support; Recruiters make hiring decisions.
6.  Protect private resumes and enforce authorization on the backend,
    database, and file storage.
7.  Keep API keys and credentials out of frontend code and source
    control.
8.  Preserve prior model versions and support evaluation, rollback, and
    audit logs.
9.  Use clear task status and error feedback for long-running or failed
    work.
10. Any unconfirmed implementation detail remains **TBD** until
    explicitly decided.
