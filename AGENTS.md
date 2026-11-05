# AGENTS.md — Instructions for coding agents

This file is read automatically by Jules and other coding agents. Read it fully before every task. Then read, in order: `PLAN.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, and the task file you were pointed to in `docs/tasks/`.

## What this project is

OpenCode's desktop GUI currently runs on an Electron backend. This project replaces that backend with a Rust implementation so the app runs well on low-resource computers, while keeping the existing GUI, UX, integrations and features. The migration is incremental, measurable, reversible and human-directed (see `PLAN.md`).

## Ground truth about upstream (leads to verify, not facts to rely on)

- Upstream is `anomalyco/opencode` (previously `sst/opencode`). The desktop app is `packages/desktop`.
- `packages/desktop` is Electron: `src/main`, `src/preload`, `src/renderer`, built with electron-vite and electron-builder, with scripts run by Bun. Source: upstream PR #25822 (https://github.com/anomalyco/opencode/pull/25822) and the package README.
- Upstream used Tauri (`src-tauri/`) before. That code was removed in the same PR but remains in upstream git history and is a useful reference for a Rust shell.
- Upstream maintainers have said the opencode server (TypeScript, moving from Bun to Node) runs embedded in Electron's main process, whereas under Tauri it ran as a separate sidecar process, and that Tauri's system webview (WebKit on macOS/Linux) rendered slower than Chromium for them.
- Upstream is mid-rewrite ("OpenCode 2.0": new API, Node migration). Treat it as a moving target and always work against the pinned snapshot in `upstream/` (see `UPSTREAM_VERSION`).

Verify each of these in the code and record what you verified, with file paths, in `docs/audit/`. If the code contradicts this section, say so in your PR. Do not silently edit this section.

## Two meanings of "backend": never guess which one

1. **The desktop shell**: Electron main and preload processes — windows, IPC, native OS integration, process management, updater.
2. **The opencode server**: the TypeScript server (sessions, providers, tools, HTTP/SSE API) that the GUI talks to.

Which of these moves to Rust, and in what order, is a human decision recorded in `docs/DECISIONS.md` (ADR-0001). **Until ADR-0001 is marked Accepted, do not write Rust production code.** Phase 1 tasks only read, measure and document.

## Repository layout

```
AGENTS.md            this file
PLAN.md              master roadmap and checklist
README.md            overview
UPSTREAM_VERSION     pinned upstream repo / ref / commit (written by the import workflow)
upstream/            pristine snapshot of upstream. READ-ONLY (see rules)
docs/                project documentation
  TASKS.md           task index: ready tasks and gated backlog
  JULES_SETUP.md     how the human starts Jules on a task
  DECISIONS.md       architecture decision log (ADRs)
  PROGRESS.md        current status, blockers, next actions
  ARCHITECTURE_AUDIT.md, RUST_ARCHITECTURE.md, COMPATIBILITY_REPORT.md
  audit/             evidence produced by Phase 1 tasks
  tasks/             one file per Jules task
  progress/          one report per completed task
scripts/             helper scripts (environment setup, baseline measurement)
crates/              Rust workspace; created in Phase 3, not before
.github/workflows/   automation
```

## Rules

1. **One task = one pull request.** Branch name: `jules/<task-id>-<short-slug>`. PR title: `[<task-id>] <short title>`. Use the PR template.
2. **Never edit `upstream/`.** It is a pristine, pinned snapshot. It changes only through the "Import upstream snapshot" workflow. To study a file, read it; to experiment, copy it elsewhere (for example under a scratch directory you do not commit).
3. **Stay inside the task.** Only create or change the files listed under "Deliverables" in your task file. Permission to do one task is not permission to refactor, rename, reformat or "tidy" anything else.
4. **Evidence over assertion.** Every factual claim in an audit document cites a file path (and line range or symbol) in `upstream/`, a commit, a command you ran, or a URL. Mark anything you inferred as *inferred* and anything you could not check as *unverified*.
5. **Do not decide, propose.** For architectural choices, add a "Proposed" entry to `docs/DECISIONS.md` with options, trade-offs and a recommendation, then stop. The project owner accepts or rejects.
6. **Verification before completion.** Never mark work done because it was generated. If you cannot run something in your VM (no GUI, no Windows or macOS, no network, no API keys), say so explicitly in the PR rather than guessing the outcome.
7. **Reports without merge conflicts.** Do not edit `docs/PROGRESS.md`. Write your report to `docs/progress/<task-id>.md` using `docs/progress/TEMPLATE.md`. The project owner updates the status table.
8. **Secrets.** Never commit tokens, API keys, credentials or real user data. Provider and credential handling is audited and documented here, not exercised with real accounts.
9. **Licensing.** Preserve upstream `LICENSE` files and notices exactly. Record any licence or branding constraints you notice in `docs/audit/`.
10. **Preserve behaviour.** The GUI, UX, integrations and features must keep working. Never silently drop functionality; list anything you cannot map as a gap.

## Working inside the Jules VM

- Linux, headless, no macOS or Windows. Claims about those platforms must come from reading code or from CI results, not from runs. Say which.
- Run Electron under a virtual display: `xvfb-run -a <command>`.
- Timing and memory numbers from the VM are noisy and not representative of the owner's low-resource machine. Record the VM's CPU and RAM next to every measurement and keep measurement scripts re-runnable elsewhere.
- Use `scripts/jules-setup.sh` as the environment setup script (see `docs/JULES_SETUP.md`).

## Commands

> To be filled in by task J-001 after the upstream build has been tried. Until then, do not assume any command works. J-001 is the only task allowed to edit this section.

## Rust conventions (apply from Phase 3 onward)

- Cargo workspace under `crates/`; toolchain pinned in `rust-toolchain.toml`.
- Before every PR touching Rust: `cargo fmt --all -- --check`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo test --workspace`.
- Every component has: a defined interface, an implementation, automated tests, compatibility tests against the recorded contract, and a rollback path (runtime switch back to the existing implementation).
- Prefer the existing communication contract (IPC channels, HTTP/SSE API) over changing the frontend. Frontend changes need an approved ADR.
- Look up current library documentation (for example Tauri, tokio, axum) rather than relying on memory; APIs change between major versions.

## Definition of done

A task is done only when: deliverables exist, acceptance criteria in the task file are each checked with evidence, tests or verification steps were run and their output is in the PR, the report file is written, and open questions and decisions needing approval are listed.
