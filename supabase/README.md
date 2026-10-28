# Database (Supabase)

| Folder | What it is |
|---|---|
| `migrations/` | The database tables and access rules, in the order they were made |
| `checks/` | A check that each user type can only see what they should |

The commands in `checks/README.md` connect to the real database. **Only the project owner runs them.**

## Migrations

| File | What it does |
|---|---|
| `20261015220000_initial_schema.sql` | The 8 tables, their status types, sign-up and status-history triggers, row level security for every role, and the private storage buckets |
| `20261015230000_private_rls_helpers.sql` | Moves the permission helper functions out of the public API schema |

A change to the database is always a new migration file (`supabase migration new <name>`), never an edit to one that is already applied. The tables are explained in [docs/database.md](../docs/database.md).
