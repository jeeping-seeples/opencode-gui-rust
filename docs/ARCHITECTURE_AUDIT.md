# OpenCode Desktop Architecture Audit (Phase 1 Deliverable)

## Executive Summary

This architecture audit synthesizes findings from Phase 1 (tasks J-001 through J-005) to evaluate migrating OpenCode's desktop application from Electron to a lightweight Rust implementation.

Upstream is `anomalyco/opencode` (v2.2.5, commit `9bbb8ce18c80f099e0e448775f59d965ead40a21`). A pivotal finding of this audit is that **the server does NOT run in-process inside Electron's main process**. Instead, the desktop application runs as two distinct tiers:
1. **The Desktop Shell**: Electron main and preload processes managing window lifecycles, native OS menus, file dialogs, auto-updates, and launching the background CLI service.
2. **The OpenCode Background Server**: A separate TypeScript daemon process (`opencode-cli serve --service`) spawned and discovered via local state files (`service.json`), communicating with the frontend GUI over loopback HTTP/SSE and WebSockets.

Empirical measurements on packaged production builds reveal an idle memory footprint of ~250–290 MB, with ~100–140 MB attributable to Electron/Chromium and ~190–250 MB attributable to the Node/Bun CLI daemon. This makes **Option A (Rust desktop shell replacing Electron while keeping the server daemon unchanged)** the cleanest, lowest-risk, and most reversible first migration milestone.

---

## 1. System Overview and Monorepo Architecture

The upstream repository is a Bun/Turbo monorepo containing 41 packages and services (`docs/audit/01-repo-and-build.md`). Key architectural components:

- **GUI Web App (Renderer)**: Located in `packages/app` (SolidJS UI design system) and mounted in `packages/desktop/src/renderer`.
- **Desktop Shell**: Located in `packages/desktop` (`src/main` Electron main process, `src/preload` bridge script, configured via `electron.vite.config.ts` and `electron-builder.config.ts`).
- **Background Server**: Located in `packages/server` (hosted by `packages/cli` as `opencode serve --service`).
- **Public Protocol**: Located in `packages/protocol` and `packages/schema`.
- **PTY Daemon**: Located in `packages/process-daemon` (native Rust binary `opencode-pty`).

---

## 2. Communication Contracts

### A. IPC & Preload Contract (`docs/audit/02-ipc-inventory.md`)
Communication between the SolidJS renderer and the desktop shell operates over two distinct layers:
1. **Preload Primitives (3 channels)**:
   - `desktop-window-snapshot`: Preloads SQLite key-value settings before page mount.
   - `desktop-rpc-port`: Transfers a high-performance `MessagePort` to the renderer on startup.
   - `opencode:drag-cancel`: Cancels drag-and-drop operations on Escape key.
2. **MessagePort RPC (64 methods + 1 event stream)**:
   - Built with typed structured cloning, bypassing Electron's JSON serialization.
   - 64 request/response RPCs covering storage (SQLite state/drafts), window state (zoom, traffic lights, focus), file pickers, and plugins.
   - 1 streaming RPC (`DesktopEvents`) pushing 13 tagged real-time desktop events (deep links, menu clicks, storage sync, zoom, fullscreen).
   - **Zero dynamic channels**: Every channel name is statically declared, facilitating 1:1 implementation in Rust.

### B. Server HTTP / SSE Contract (`docs/audit/03-server-contract.md`)
- **Discovery**: Handled via `$XDG_STATE_HOME/opencode/service.json` storing `{ url, pid, password }`.
- **Authentication**: Loopback requests use HTTP Basic auth (`opencode:<password>`). The desktop shell intercepts renderer loopback requests and injects the `Authorization` header, shielding credentials from JavaScript.
- **REST API**: Documented in `docs/audit/openapi/openapi.json` with 138 paths and 169 operations.
- **Streaming**:
  - SSE at `GET /api/event` with 15-second heartbeat comments (`: heartbeat\n\n`) and durable sequence IDs.
  - WebSockets at `/api/pty/{id}/connect` and `/api/experimental/persistent-pty/{id}/connect` for terminal emulation.

---

## 3. Native & Platform Features (`docs/audit/04-native-features.md`)

A comprehensive audit of 18 desktop-native capabilities confirmed:
- Window state management, menus, clipboard, external URL opening, single-instance lock, and file dialogs map directly to standard Tauri v2 plugins (`tauri-plugin-window-state`, `tauri-plugin-dialog`, `tauri-plugin-clipboard-manager`, `tauri-plugin-single-instance`, `tauri-plugin-opener`).
- **Auto-updater** represents the primary difference: upstream uses `electron-updater` reading YAML feeds (`desktop.yml`), whereas Tauri uses JSON manifests. A translation adapter or server feed endpoint will be required in Phase 3.
- **Webview Rendering**: Shifting from Chromium to system webviews (WebKitGTK on Linux, WKWebView on macOS, WebView2 on Windows) preserves the frontend UI without changes, but font rendering on Linux must be verified against WebKitGTK.

---

## 4. Baseline Performance Findings (`docs/audit/05-baseline.md`)

From 5 consecutive packaged app runs measured via `scripts/baseline/measure.py`:
- **Startup Time**: ~30.9 seconds (under virtual headless X11 display in cloud VM).
- **Idle Memory (PSS)**: 247.7 MB median whole-process tree.
- **Process Memory Breakdown**:
  - Background CLI daemon (`opencode-cli serve --service`): ~190–250 MB.
  - Electron process tree (main + GPU + renderer + crashpad): ~100–140 MB.
  - CPU: 0.0%–1.0% idle CPU.

---

## 5. Architectural Seams & Migration Boundaries

Three candidate migration boundaries were evaluated:

1. **Seam 1: The Desktop Shell (Narrow & Clean — Highly Recommended)**
   - **Boundary**: Replacing Electron's `packages/desktop/src/main` and `src/preload` with a Rust Tauri shell.
   - **Properties**:
     - The renderer already communicates over a clean `MessagePort` RPC layer (`docs/audit/ipc-inventory.json`).
     - The background server is already decoupled as a detached child process daemon.
     - Saves ~100+ MB idle RAM and removes Chromium dependencies from disk/RAM.
     - Preserves 100% of upstream frontend code without modifications.
2. **Seam 2: High-Performance Server Subsystems (Secondary Target)**
   - **Boundary**: Porting specific server modules behind the existing HTTP/SSE API (ripgrep file search, PTY management, VCS/git).
   - **Properties**: `packages/process-daemon` is already written in Rust. Other modules can be selectively ported in Phase 3/4.
3. **Seam 3: Full Server Rewrite (High Risk — Not Recommended)**
   - **Boundary**: Rewriting the entire Effect-TS server into Rust.
   - **Properties**: Upstream is actively rewriting this layer (OpenCode 2.0). High drift risk and substantial engineering effort with marginal benefit over Seam 1.

---

## 6. Risk Register

| Risk | Impact | Probability | Mitigation Strategy |
|---|---|---|---|
| **Upstream API Drift** | High | High | Work strictly against pinned release snapshot `v2.2.5` (`UPSTREAM_VERSION`). Re-run contract checks when updating. |
| **Linux WebKitGTK Glitches** | Med | Med | Retain fallback to Electron shell via runtime switch `OPENCODE_SHELL=electron|rust`. |
| **Auto-Updater Feed Mismatch** | Med | High | Build a lightweight adapter layer translating Tauri update JSON requests to existing release endpoints. |
| **PTY Terminal Compatibility** | Low | Low | Upstream `process-daemon` is already in Rust, providing a reliable reference. |

---

## 7. Recommendation for ADR-0001

**Proceed with Option A as Milestone 1**:
Build a Rust desktop shell (Tauri v2) that:
1. Implements the 67 IPC and preload channels cataloged in `docs/audit/ipc-inventory.json`.
2. Spawns and manages `opencode-cli serve --service` via loopback HTTP.
3. Keeps the existing SolidJS renderer and TypeScript server completely unchanged.
4. Provides an automatic rollback path to Electron via environment variable.

After Milestone 1 demonstrates stable operation and performance gains, evaluate **Option B** (porting individual heavy server subsystems) based on updated memory profiles.
