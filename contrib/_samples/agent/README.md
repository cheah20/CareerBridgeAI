# Agent screen samples

Sample data for the screens that show the AI agents' work. Build your page so it shows every field clearly. Later, Cheah swaps the sample file for the real agent output in the same format, so keep the field names.

| File | Screen | Card owner |
|---|---|---|
| `approval-queue.json` | Approval queue: actions waiting for a person to approve | Ong |
| `agent-trace.json` | Agent trace: every step a run took | Ong |
| `evidence-report.json` | Evidence report: each skill with its proof, and the candidate's reply | Fiqz |
| `evidence-reply.json` | Evidence reply form: what the candidate sees when asked for proof | Fiqz |
| `coach-chat.json` | Career coach chat | Fathiyah |
| `mission-board.json` | Mission board: plan steps and the match going up | Fathiyah |

## Field notes

- `status` on a trace step: `ok`, `retry` (failed once, tried again) or `failed`. Show retries clearly: they prove the agent recovers.
- `level` on an approval: `L3` means it affects another person, so a person must approve it.
- `evidence_level`: `hypothetical`, `self_reported`, `documented` or `verified`. Show them differently, for example a dashed tag for self-reported.
- `why_next` is a short reason for the next step, not the model's hidden thinking.

All names, companies and links are made up.
