# Task index

One task = one pull request. Each ready task has a self-contained file in `docs/tasks/` to give to Jules. Status is tracked in `docs/PROGRESS.md`.

## Ready tasks (Phase 1 — Study)

| ID | Task | Blocked by | File |
|---|---|---|---|
| J-000 | Import upstream snapshot (owner runs the workflow; no agent) | none | `.github/workflows/import-upstream.yml` |
| J-001 | Repo, build and version audit | J-000 | `docs/tasks/J-001-repo-and-build-audit.md` |
| J-002 | IPC and preload inventory | J-001 | `docs/tasks/J-002-ipc-and-preload-inventory.md` |
| J-003 | Server contract inventory | J-001 | `docs/tasks/J-003-server-contract-inventory.md` |
| J-004 | Native and platform features inventory | J-001 | `docs/tasks/J-004-native-features-inventory.md` |
| J-005 | Baseline performance measurements | J-001 | `docs/tasks/J-005-baseline-measurements.md` |
| J-006 | Phase 1 synthesis and ADR-0001 proposal | J-001 to J-005 | `docs/tasks/J-006-phase1-synthesis.md` |

J-002 to J-005 write different files and can run in parallel.

## Gated backlog (Phases 2 to 5)

**Gate:** nothing below starts until the owner marks **ADR-0001 Accepted** in `docs/DECISIONS.md`. These are outlines, not Jules-ready prompts. J-006 refines them from audit evidence, and each is expanded into a full task file (same format as above) just before it is started.

### Phase 2 — Architecture and design

- **J-100** Draft `docs/RUST_ARCHITECTURE.md` for the accepted option: crate layout, async runtime, IPC/HTTP contract handling, error handling and logging, configuration, process lifecycle and shutdown, cross-platform requirements. Owner approves before Phase 3.
- **J-101** Test strategy: contract-test harness design (how the IPC and HTTP/SSE inventories become executable tests that run against both the Electron and the Rust implementation), screenshot comparison approach, performance benchmark protocol.

### Phase 3 — Build (ordering to be confirmed by the audit)

Foundation:
- **J-200** Cargo workspace, `rust-toolchain.toml`, fmt/clippy/test CI, build matrix for Linux, macOS and Windows.
- **J-201** Hello-window: a Rust shell that loads the existing, unchanged renderer, built side by side with the Electron app.

Shell (applies to options A and B):
- **J-202** Server process manager: spawn, health check, port/credential hand-off, graceful shutdown, crash recovery.
- **J-203** IPC compatibility layer, in several PRs grouped by channel family from `docs/audit/ipc-inventory.json`, so the renderer sees the same API.
- **J-204** Settings/store, window state, single-instance lock, logging.
- **J-205** Menus, tray, deep links, notifications, dialogs.
- **J-206** Updater, packaging and installers for each supported target.
- **J-207** Runtime switch (for example `OPENCODE_SHELL=electron|rust`) as the rollback path, and a launcher that falls back safely.

Server modules (option B only; module order from the audit, one module per task):
- **J-3xx** Port a module behind the existing HTTP/SSE contract with shadow-mode comparison against the TypeScript module and a runtime switch back.

### Phase 4 — Check

- **J-400** Run the contract-test harness against both implementations; record differences.
- **J-401** Performance comparison using the J-005 scripts: start-up, idle and peak memory, CPU, responsiveness under load.
- **J-402** Fill `docs/COMPATIBILITY_REPORT.md`; list every unexplained regression.

### Phase 5 — Ready

- **J-500** Clean-install and upgrade/migration verification.
- **J-501** Release targets, installation and troubleshooting docs, release notes.
