
OpenCode Rust Backend Migration

Project status: Backlog / Not started
Priority: Experimental
Development environment: Cloud coding agents
Primary implementation language: Rust
Existing GUI: Preserve
Project approach: Incremental migration

Vision

Replace the existing OpenCode GUI application’s backend with a Rust implementation while preserving the existing GUI, user experience, integrations and functionality.

The project must be developed primarily through cloud-based coding agents because local development hardware is limited.

The migration must be incremental, measurable, reversible and human-directed.

Core principles

* Preserve the existing GUI wherever possible.
* Never rewrite working components without a demonstrated reason.
* Maintain compatibility with existing interfaces.
* Prefer small, independently testable changes.
* Require approval before major architectural decisions.
* Every change must have a test or verification procedure.
* Maintain a working application throughout migration.
* Never silently remove existing functionality.
* Keep progress, decisions and blockers documented.

⸻

PHASE 1 — STUDY

Goal: Understand the original application before changing anything.

Repository investigation

* [x]	Identify the official upstream repository and exact version/commit (docs/audit/01-repo-and-build.md).
* [x]	Identify the GUI framework and frontend architecture (docs/audit/01-repo-and-build.md).
* [x]	Identify the existing backend language and framework (docs/audit/01-repo-and-build.md).
* [x]	Map the frontend/backend communication layer (docs/audit/02-ipc-inventory.md).
* [x]	Identify all backend entry points (docs/audit/02-ipc-inventory.md, docs/audit/03-server-contract.md).
* [x]	Map existing modules and dependencies (docs/audit/01-repo-and-build.md).
* [x]	Identify configuration and environment requirements (docs/audit/03-server-contract.md).
* [x]	Document build, development and release procedures (docs/audit/01-repo-and-build.md).

Functional investigation

* [x]	Catalogue all existing GUI features (docs/audit/04-native-features.md).
* [x]	Identify every backend-dependent feature (docs/audit/02-ipc-inventory.md, docs/audit/04-native-features.md).
* [x]	Document API endpoints and request/response formats (docs/audit/03-server-contract.md, docs/audit/openapi/openapi.json).
* [x]	Document streaming and event behaviour (docs/audit/03-server-contract.md).
* [x]	Document process and filesystem operations (docs/audit/03-server-contract.md).
* [x]	Document authentication and provider integrations (docs/audit/03-server-contract.md).
* [x]	Identify platform-specific functionality (docs/audit/04-native-features.md).

Baseline

* [x]	Establish existing build/test baseline (docs/audit/01-repo-and-build.md, docs/audit/05-baseline.md).
* [x]	Record startup time (docs/audit/05-baseline.md).
* [x]	Record idle memory consumption (docs/audit/05-baseline.md).
* [x]	Record representative CPU usage (docs/audit/05-baseline.md).
* [x]	Identify existing bugs and limitations (docs/audit/01-repo-and-build.md, docs/audit/04-native-features.md).
* [ ]	Capture GUI screenshots at relevant screen sizes (Unverified in headless VM due to virtual display limitation).

Deliverable

docs/ARCHITECTURE_AUDIT.md

Exit criteria: We understand the existing application well enough to identify safe migration boundaries.

⸻

PHASE 2 — ARCHITECTURE & DESIGN

Goal: Design the Rust replacement without prematurely committing to an implementation.

* [ ]	Identify which backend components should move to Rust.
* [ ]	Identify components that should remain unchanged.
* [ ]	Select Rust application architecture.
* [ ]	Select asynchronous runtime where necessary.
* [ ]	Design frontend/backend communication.
* [ ]	Define API compatibility requirements.
* [ ]	Define error handling and logging.
* [ ]	Define configuration management.
* [ ]	Define process lifecycle and shutdown behaviour.
* [ ]	Define testing strategy.
* [ ]	Define cross-platform requirements.

Important decision

Prefer a Rust backend that implements the existing communication contract rather than forcing a frontend rewrite.

Deliverable

docs/RUST_ARCHITECTURE.md

Exit criteria: Architecture is documented and approved before implementation.

⸻

PHASE 3 — BUILD

Goal: Implement the replacement in small, independently verifiable stages.

Foundation

* [ ]	Set up Rust workspace.
* [ ]	Configure dependency management.
* [ ]	Configure formatting and linting.
* [ ]	Configure automated CI builds.
* [ ]	Establish baseline integration tests.

Backend components

The final ordering must be determined by the architecture audit.

* [ ]	Implement configuration management.
* [ ]	Implement filesystem services.
* [ ]	Implement process management.
* [ ]	Implement session/task management.
* [ ]	Implement API communication.
* [ ]	Implement streaming and event handling.
* [ ]	Implement logging and diagnostics.
* [ ]	Implement provider integration compatibility.
* [ ]	Implement graceful shutdown and recovery.

Integration

* [ ]	Connect Rust backend to existing GUI.
* [ ]	Validate request/response compatibility.
* [ ]	Validate streaming behaviour.
* [ ]	Validate error propagation.
* [ ]	Validate authentication.
* [ ]	Validate existing integrations.
* [ ]	Validate application startup and shutdown.

Migration rules

Every component must:

1. Have a defined interface.
2. Have an implementation.
3. Have automated tests.
4. Pass compatibility tests.
5. Be independently reviewable.
6. Have a rollback path.

Deliverable

A functioning hybrid application with progressively more Rust backend functionality.

⸻

PHASE 4 — CHECK

Goal: Establish that the replacement is actually equivalent or better.

Functional compatibility

* [ ]	Compare GUI functionality against original.
* [ ]	Test all documented backend operations.
* [ ]	Test provider integrations.
* [ ]	Test session persistence.
* [ ]	Test streaming and interruption.
* [ ]	Test error handling.
* [ ]	Test recovery after failures.
* [ ]	Check for missing functionality.

Performance

* [ ]	Compare startup time.
* [ ]	Compare idle memory usage.
* [ ]	Compare peak memory usage.
* [ ]	Compare CPU usage.
* [ ]	Compare responsiveness under load.
* [ ]	Identify regressions.

Reliability

* [ ]	Run automated regression suite.
* [ ]	Run integration tests.
* [ ]	Test repeated application launches.
* [ ]	Test interrupted operations.
* [ ]	Test configuration migration.
* [ ]	Verify clean shutdown.

Deliverable

docs/COMPATIBILITY_REPORT.md

Exit criteria: No unexplained functional regressions, with performance results documented.

⸻

PHASE 5 — READY

Goal: Produce a usable replacement.

* [ ]	Complete backend migration.
* [ ]	Remove obsolete backend components only when safe.
* [ ]	Verify clean installation.
* [ ]	Verify upgrade/migration procedures.
* [ ]	Build supported release targets.
* [ ]	Document installation.
* [ ]	Document troubleshooting.
* [ ]	Create release notes.
* [ ]	Publish first stable release.

Final acceptance criteria

* Existing GUI remains functional.
* Required features have passed compatibility tests.
* Rust backend builds reproducibly.
* No critical regressions remain.
* Installation and recovery procedures are documented.
* Performance comparison is available.
* Source code and build instructions are published.

⸻

PROJECT OPERATING SYSTEM

Agent workflow

All coding agents must follow this workflow:

1. Read PLAN.md and current project status.
2. Read architecture documentation.
3. Select one approved task.
4. Explain intended changes before implementation.
5. Implement the smallest reasonable change.
6. Run relevant tests.
7. Report files changed and test results.
8. Update project documentation.
9. Submit a pull request.
10. Wait for human approval before merging major changes.

Human control

The project owner can:

* Approve or reject proposed changes.
* Interrupt an active task.
* Change implementation priorities.
* Request revisions.
* Reject architectural decisions.
* Pause the migration.
* Return to earlier milestones.

Agents must not interpret permission to work on one task as permission to undertake unrelated refactoring.

Required repository files

* PLAN.md — master project roadmap and checklist.
* README.md — project overview and setup.
* AGENTS.md — instructions for coding agents.
* docs/ARCHITECTURE_AUDIT.md — original application investigation.
* docs/RUST_ARCHITECTURE.md — target architecture.
* docs/COMPATIBILITY_REPORT.md — testing and comparison results.
* docs/DECISIONS.md — architectural decision log.
* docs/PROGRESS.md — current status, blockers and next actions.

Progress reporting format

Every completed task should record:

* Task identifier.
* Previous state and new state.
* Files changed.
* Tests executed and results.
* Known issues.
* Decisions requiring approval.
* Recommended next task.

Important: Never mark a task complete merely because code was generated. Completion requires verification.

⸻

ADDENDUM — PROJECT SETUP (2026-11-05)

Upstream facts found while setting up (to be verified in Phase 1)

* Upstream is anomalyco/opencode (formerly sst/opencode). Its desktop app (packages/desktop) is now Electron, replacing an earlier Tauri build.
* "Backend" is ambiguous: it can mean the Electron shell (main/preload) or the TypeScript opencode server the GUI talks to. Upstream reports the server runs inside Electron's main process (it was a sidecar under Tauri). Which layer moves to Rust is decided in docs/DECISIONS.md, ADR-0001, using Phase 1 measurements. No Rust production code is written before that decision is Accepted.
* Upstream is mid-rewrite, so the project works against a pinned snapshot in upstream/ (ADR-0002).

How the phases map to agent tasks

* Phase 1 — Study: tasks J-001 to J-006 (docs/tasks/). Ready to run.
* Phases 2 to 5: gated backlog in docs/TASKS.md, expanded into full task files after ADR-0001 is Accepted.

Where to start: docs/JULES_SETUP.md.
