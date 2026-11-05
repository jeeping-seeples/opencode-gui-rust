# Decision log

Format: one entry per decision. Status is one of **Proposed**, **Accepted**, **Rejected**, **Superseded**. Only the project owner changes a status to Accepted or Rejected. Agents may add Proposed entries.

---

## ADR-0001 — What "Rust backend" means and the target architecture

**Status:** Proposed — awaiting owner decision after Phase 1 evidence (J-005 baseline, J-006 synthesis).

### Context

The goal is to run OpenCode's desktop GUI well on low-resource computers using a Rust backend instead of Electron.

"Backend" can mean two different layers:

1. The **desktop shell** (Electron main and preload: windows, IPC, OS integration, updater, process management).
2. The **opencode server** (TypeScript: sessions, providers, tools, HTTP/SSE API).

Reported facts about upstream (to be verified by J-001 to J-003):

- Upstream's desktop app moved from Tauri to Electron. See https://github.com/anomalyco/opencode/pull/25822.
- Upstream maintainers said the server had to run as a sidecar under Tauri, which added start-up cost, IPC latency and stability problems, and that Tauri had little Rust code to benefit from. See https://x.com/vikingmute/status/2045503577377099843 (summary of their reply) and https://x.com/brendonovich/status/2045114479244165151.
- A report on OpenCode 2.0 says Tauri's system webview (WebKit on macOS and Linux) performed worse than Chromium, and that the server code can run inside Electron's Node process. It also says 2.0 includes an API overhaul and a Bun-to-Node migration, motivated partly by memory use. See https://www.kucoin.com/news/flash/opencode-2-0-major-rewrite-api-overhaul-node-migration-and-electron-desktop-shift.

Implication: replacing only the shell may save less than hoped, because the JavaScript server and a system webview remain. Replacing the server is a much larger and faster-moving target. The decision should rest on measurements from J-005, not on assumptions.

### Phase 1 Audit Evidence Summary (Added 2026-11-05)

The Phase 1 audits (J-001 through J-005) established crucial empirical facts:
1. **Server Process Topology**: The server does NOT run inside Electron's main process in upstream v2.2.5. It runs as a detached child process daemon (`opencode-cli serve --service`) communicating over loopback HTTP/SSE.
2. **IPC Contract Cleanliness**: The renderer talks to the shell over 3 preload primitives and a 64-method MessagePort RPC interface (`docs/audit/ipc-inventory.json`). Zero dynamic channels exist.
3. **Resource Breakdown**: Packaged Electron app idle memory is ~250-290 MB total PSS: ~100-140 MB belongs to the Electron/Chromium shell, and ~190-250 MB belongs to the Node/Bun CLI daemon (`docs/audit/05-baseline.md`).
4. **Feasibility**: All 18 desktop-native features map directly to Tauri v2 plugins or Rust crates (`docs/audit/04-native-features.md`).

### Options

**A — Rust shell, existing server unchanged.** A Rust desktop shell (likely Tauri) replaces Electron main/preload. The existing server runs as a sidecar. The renderer is unchanged.
- For: smallest change; removes Electron/Chromium from the process tree; reversible; upstream's old Tauri code is a reference.
- Against: JS server memory remains; upstream reported sidecar overhead and WebKit rendering differences; gains may be modest.

**B — A, then port server modules to Rust one at a time.** Each ported module sits behind the existing HTTP/SSE contract, validated in shadow mode (run both, diff outputs) with a runtime switch back to the TypeScript module.
- For: incremental, measurable, reversible; targets the biggest resource users first (as shown by data).
- Against: the server surface is large and upstream is rewriting its API; pinning and rebasing costs are real.

**C — Full Rust rewrite of the server in one go.**
- Against: conflicts with this project's principles (small, independently testable, always-working). Not recommended.

### Recommendation (non-binding)

Adopt **Option A** as Milestone 1:
- The Phase 1 audit conclusively demonstrated that the Electron shell accounts for ~100-140 MB of idle RAM and significant binary size.
- Replacing the shell with Tauri v2 leaves the renderer and server 100% unchanged, offering the lowest risk, easiest rollback path, and fastest delivery.
- Evaluate **Option B** as a data-driven follow-on after Milestone 1 is verified on target hardware.
- Reject **Option C**.

### Decision

*(owner fills in: option, conditions, date)*

---

## ADR-0002 — Upstream pinning and drift policy

**Status:** Proposed.

### Context

Upstream is changing quickly (2.0 rewrite). A moving target breaks compatibility work.

### Proposal

- Import a release tag, not `dev`, via the "Import upstream snapshot" workflow. Record it in `UPSTREAM_VERSION`.
- Re-import only deliberately, as its own PR, followed by a re-run of the contract inventory (J-002, J-003) to detect drift.
- Contract tests (Phase 4) run against the pinned version.

### Decision

*(owner fills in)*
