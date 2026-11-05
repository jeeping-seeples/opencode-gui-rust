# Progress

**Current phase:** Phase 1 — Study
**Last updated:** 2026-11-05 (project scaffold created)

## Next actions (owner)

1. Run the "Import upstream snapshot" workflow and merge the PR (see `docs/JULES_SETUP.md`).
2. Start Jules on `J-001`.

## Blockers

- `upstream/` does not exist yet, so no task can start until the import is merged.
- ADR-0001 (what "Rust backend" means) is undecided. It blocks all Rust code, by design.

## Task status

Agents do not edit this table. The owner updates it after reviewing each PR. Details are in `docs/progress/<task-id>.md`.

| Task | Title | Status | PR | Report |
|---|---|---|---|---|
| J-000 | Import upstream snapshot (owner, via workflow) | Not started | | |
| J-001 | Repo, build and version audit | Blocked by J-000 | | |
| J-002 | IPC and preload inventory | Blocked by J-001 | | |
| J-003 | Server contract inventory | Blocked by J-001 | | |
| J-004 | Native and platform features inventory | Blocked by J-001 | | |
| J-005 | Baseline performance measurements | Blocked by J-001 | | |
| J-006 | Phase 1 synthesis and ADR-0001 proposal | Blocked by J-001 to J-005 | | |

## Log

- 2026-11-05: Scaffold created: AGENTS.md, task files J-001 to J-006, gated backlog, import workflow, Jules setup script.
