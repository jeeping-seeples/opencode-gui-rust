# opencode-gui-rust

OpenCode GUI with a Rust backend instead of Electron, for low-resource computers.

**Status:** Phase 1 (Study) ready to start. No Rust code yet by design; see `PLAN.md`.

## How this project works

- The existing OpenCode GUI is preserved. The backend is replaced incrementally, behind the interfaces the GUI already uses.
- Work is done by cloud coding agents (Jules) in small tasks, one pull request each. A human reviews and approves.
- Upstream (`anomalyco/opencode`, `packages/desktop`) is imported as a pinned, read-only snapshot in `upstream/`.

## Where things are

| File | Purpose |
|---|---|
| `PLAN.md` | Master roadmap, phases and checklists |
| `AGENTS.md` | Rules and context for coding agents (read first) |
| `docs/JULES_SETUP.md` | How to start Jules on a task, step by step |
| `docs/TASKS.md` | Task index: what is ready, what is gated |
| `docs/tasks/` | One self-contained prompt file per task |
| `docs/DECISIONS.md` | Architecture decisions (ADR-0001 is the big open one) |
| `docs/PROGRESS.md` | Current status, blockers, next actions |
| `docs/ARCHITECTURE_AUDIT.md` | Phase 1 deliverable |
| `docs/RUST_ARCHITECTURE.md` | Phase 2 deliverable |
| `docs/COMPATIBILITY_REPORT.md` | Phase 4 deliverable |

## Getting started

Follow `docs/JULES_SETUP.md`. In short: run the "Import upstream snapshot" workflow, connect this repo in Jules, then give Jules task `J-001`.

## Licence

Upstream OpenCode code in `upstream/` keeps its original licence. This repository's own licence is to be chosen by the owner and added as `LICENSE`.
