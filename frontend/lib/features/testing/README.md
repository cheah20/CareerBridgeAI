# Resume analysis (testing mode)

Upload a resume and see the fit score, skills and tips. Works without login, only on the developer's computer.

| File | What it is |
|---|---|
| `resume_analysis_page.dart` | The upload form |
| `assessment_view.dart` | The result page: score, tabs, skills, jobs, details |
| `analysis_result_view.dart` | Picks the right result layout (also shows older results) |
| `logbook_page.dart` | List of past test results |
| `testing_api.dart` | Talks to the backend |

Results are kept in `ai_backend/data/logbook/` on the developer's computer, not in the database.
