# Audit: Server Contract Inventory (J-003)

## Overview

This document audits the complete contract between the desktop client (Electron shell + SolidJS GUI) and the OpenCode background server (`packages/server` hosted by `packages/cli`).

In OpenCode v2.2.5, **the server does NOT run inside Electron's main process**. Instead, the server runs as an independent daemon (`opencode serve --service`) managed via a discovery and health-checking protocol over state files, loopback HTTP/SSE, and WebSockets.

---

## 1. Server Lifecycle

The server lifecycle is managed through `packages/desktop/src/main/service/background-service.ts` using `@opencode/client/service` (`packages/client/src/promise/service.ts`).

### Step-by-Step Lifecycle Sequence

1. **Resolution & Staging**:
   - Source: `packages/desktop/src/main/service/desktop-cli.ts:40-75`.
   - In development: resolves `packages/cli/src/index.ts` executed via `bun run`.
   - In packaged production or isolated mode: resolves `resources/opencode-cli` (or downloads the platform baseline) and stages it under `userData/cli/<stage>/opencode-cli`.
2. **Early Health Probe**:
   - Source: `packages/desktop/src/main/service/sidecar-probe.ts:9-25`.
   - When the first window is created before main layers finish booting, an early probe (`import('@opencode/client/service').then(s => s.discover(...))`) checks if a compatible background service is already running by reading the registration file (`~/.local/state/opencode/service.json` or `XDG_STATE_HOME/opencode/service.json`).
3. **Daemon Ensure & Contender Spawn**:
   - Source: `packages/client/src/promise/service.ts:33-85`.
   - If no healthy service is found or if the running version does not match `requiredVersion`, `Service.ensure()` spawns a new service process:
     - Command: `opencode-cli serve --service [--hostname 0.0.0.0 --port 3084]`.
     - In isolated dev mode: sets `--hostname 0.0.0.0 --port 3084` (`0x0c0c`). In production: allows OS port assignment (`127.0.0.1:<random-port>`).
4. **Registration File Discovery & Authentication**:
   - Location: `$XDG_STATE_HOME/opencode/service.json` (or `~/.local/state/opencode/service.json`).
   - Contents:
     ```json
     {
       "id": "<uuid>",
       "version": "2.2.5",
       "url": "http://127.0.0.1:49374",
       "pid": 169003,
       "password": "<random-base64url-secret>"
     }
     ```
5. **Readiness Probe**:
   - Source: `packages/client/src/service-probe.ts:40-75`.
   - Polling checks `GET /api/info` with HTTP Basic Authorization header (`Basic base64('opencode:' + password)`).
   - If `/api/info` returns status 200 with matching PID and version, the state is marked `ready`.
6. **Credentials & Proxying to Renderer**:
   - Source: `packages/desktop/src/main/service/sidecar-credentials.ts:25-45` and `packages/desktop/src/main/windows/security.ts:100-113`.
   - The desktop main process returns `{ url: 'http://127.0.0.1:49374' }` to the renderer via `AppAwaitInitialization`.
   - **Crucial Security Detail**: The renderer never receives the server password in JavaScript. Instead, Electron's `session.webRequest.onBeforeSendHeaders` intercepts all loopback requests from the renderer frame to `http://127.0.0.1/*` and injects the HTTP `Authorization: Basic ...` header automatically. This prevents CORS preflights and keeps credentials isolated in the native shell.
7. **Shutdown & Restart Sequence**:
   - Source: `packages/client/src/promise/service.ts:87-145`.
   - On restart / replacement / shutdown, `Service.stop()` sends `SIGTERM` to the daemon PID, waiting up to `stopPollAttempts` (default 500ms intervals).
   - If the daemon does not terminate cleanly, it escalates to `SIGKILL` and unlinks the `service.json` state file.
   - Persistent PTY terminals can be optionally handed off via `PtyHandoff.prepare()` before termination.

---

## 2. Configuration & State Paths

OpenCode configuration adheres to the XDG Base Directory specification across all operating systems (`packages/util/src/global-roots.node.ts`):

| Directory Role | Linux / Fallback | macOS (`process.platform === 'darwin'`) | Windows (`process.platform === 'win32'`) | Environment Override |
|---|---|---|---|---|
| **Config** | `~/.config/opencode` | `~/Library/Application Support/opencode` | `%APPDATA%\opencode` | `OPENCODE_CONFIG_DIR` or `XDG_CONFIG_HOME` |
| **Data** | `~/.local/share/opencode` | `~/Library/Application Support/opencode` | `%LOCALAPPDATA%\opencode` | `XDG_DATA_HOME` |
| **State** | `~/.local/state/opencode` | `~/Library/Application Support/opencode` | `%LOCALAPPDATA%\opencode` | `XDG_STATE_HOME` |
| **Cache** | `~/.cache/opencode` | `~/Library/Caches/opencode` | `%LOCALAPPDATA%\opencode\cache` | `XDG_CACHE_HOME` |
| **Tmp** | `/tmp/opencode` | `/tmp/opencode` | `%TEMP%\opencode` | OS temp dir |

### Key Configuration Files
- `config.json` (under config directory): Main application settings, default model selection, editor preferences, agent presets.
- `service.json` (under state directory): Active daemon endpoint, PID, and basic auth password.
- `opencode.db` (under data directory): Primary SQLite database storing sessions, projects, messages, permissions, and VCS state.

---

## 3. HTTP REST API Contract

The server exposes an OpenAPI 3.1 specification generated by `packages/protocol/script/generate-openapi.ts`. A full pristine snapshot has been copied to `docs/audit/openapi/openapi.json`.

The API comprises **138 route paths and 169 distinct operations**, implemented using Effect HttpApi in `packages/server` and consumed via the typed SDK client in `packages/client/src/promise/generated/client.ts`.

### Route Inventory Summary & GUI Usage

| API Group | Key Routes | Methods | GUI-Used | Primary Purpose |
|---|---|---|---|---|
| **Server** | `/api/info`, `/api/pair`, `/auth/connect/{code}` | `GET`, `POST` | **YES** | Health checks, pairing with mobile/remote web UI, OAuth connection. |
| **Session** | `/api/session`, `/api/session/{id}`, `/api/session/active`, `/api/session/{id}/*` | `GET`, `POST`, `PATCH`, `DELETE` | **YES** | Core conversation sessions, switching models/agents, forking, compacting, history. |
| **Prompt & Chat** | `/api/session/{id}/prompt`, `/api/session/{id}/message`, `/api/session/{id}/interrupt` | `POST`, `GET` | **YES** | Prompt submission, message pagination, interrupting running agent generations. |
| **Events** | `/api/event` | `GET` (SSE) | **YES** | Server-Sent Events stream for real-time state synchronization. |
| **Filesystem** | `/api/fs/find`, `/api/fs/list`, `/api/fs/read/*` | `GET` | **YES** | Workspace directory tree, file searching (ripgrep/fff), media content streaming. |
| **PTY / Terminal** | `/api/pty`, `/api/pty/{id}`, `/api/pty/{id}/connect`, `/api/experimental/persistent-pty/*` | `GET`, `POST`, `PUT`, `DELETE` | **YES** | Interactive shell sessions and persistent PTY terminal connections (WebSocket). |
| **VCS / Git** | `/api/vcs`, `/api/vcs/status`, `/api/vcs/branch`, `/api/vcs/diff`, `/api/worktree` | `GET`, `POST`, `DELETE` | **YES** | Git branch detection, diff computation, working tree status, staged changes. |
| **Permissions** | `/api/permission/request`, `/api/permission/saved`, `/api/session/{id}/permission/*` | `GET`, `POST`, `PATCH`, `DELETE` | **YES** | User approval of tool actions (shell exec, file write, external API calls). |
| **Forms / Questions** | `/api/form`, `/api/session/{id}/form/*` | `GET`, `POST`, `DELETE` | **YES** | Interactive UI questionnaires and user elicitation during task execution. |
| **Models & Providers** | `/api/model`, `/api/model/default`, `/api/provider`, `/api/credential/*` | `GET`, `POST`, `PATCH`, `DELETE` | **YES** | LLM model list, default model configuration, API key and OAuth credential management. |
| **MCP** | `/api/mcp`, `/api/mcp/resource`, `/api/experimental/mcp/*` | `GET`, `PUT`, `POST`, `DELETE` | **YES** | Model Context Protocol server connection, discovery, and tool integration. |
| **Plugins** | `/api/plugin`, `/api/plugin/gui`, `/api/plugin/check`, `/api/plugin/update` | `GET`, `POST` | **YES** | Plugin status, GUI plugin manifest discovery, plugin updates. |
| **Location & Project** | `/api/location`, `/api/location/reload`, `/api/project` | `GET`, `POST`, `PATCH` | **YES** | Workspace root location, project metadata, directory reloading. |
| **Voice & Audio** | `/api/experimental/voice/models`, `/api/experimental/voice/session` | `GET`, `POST` | **YES** | Voice conversation sessions and speech-to-text integration. |
| **Debug / Diagnostics** | `/api/debug/heap-dump`, `/api/debug/location` | `GET`, `POST`, `DELETE` | No (Dev) | Internal memory profiling and diagnostic endpoints. |

---

## 4. Real-Time Streaming (SSE & WebSockets)

### 1. Server-Sent Events (`GET /api/event`)
- **Implementation**: `packages/server/src/handlers/event.ts:10-35`.
- **Headers**: `Content-Type: text/event-stream`, `Cache-Control: no-cache, no-transform`, `X-Accel-Buffering: no`.
- **Initial Event**: First event emitted is immediately `{ id: '...', type: 'server.connected', data: {} }`.
- **Heartbeat / Keepalive**: A comment `: heartbeat\n\n` is sent every 15 seconds. If the client receives no bytes for 45 seconds (`defaultIdleTimeout`), it automatically aborts and reconnects.
- **Event Payloads**: Typed JSON events defined in `@opencode/schema/event` (e.g. `session.created`, `session.updated`, `message.updated`, `permission.requested`, `form.created`, `vcs.status.updated`).
- **Durable Sequencing**: Events contain `durable: { aggregateID, seq }` allowing the client data cache (`@opencode/client/solid`) to detect missed messages and resynchronize.

### 2. PTY and Terminal Streams (WebSockets)
- **Endpoints**: `/api/pty/{ptyID}/connect` and `/api/experimental/persistent-pty/{ptyID}/connect`.
- **Protocol**: Raw binary and JSON control framing over WebSocket.
- **Backend Implementation**: `packages/process-daemon` (Rust-based `opencode-pty` daemon) and `packages/core/src/persistent-pty/daemon.ts`.
- **Handoff & Persistence**: Shells remain running across server restarts if `--pty handoff` is requested during clean reload.

---

## 5. Persistence & Storage Format

1. **Database Engine**: SQLite 3 with WAL mode enabled (`PRAGMA journal_mode = WAL`, `PRAGMA synchronous = NORMAL`, `PRAGMA busy_timeout = 5000`).
2. **ORM / Migrations**: Drizzle ORM (`packages/core/src/database/database.ts`).
   - Primary database file: `$XDG_DATA_HOME/opencode/opencode.db`.
   - File security: Automatically restricted to owner permissions `0o600` on POSIX (`chmod(filename, 0o600)`).
3. **Core Database Tables** (from `packages/core/src/database/schema.gen.ts`):
   - `project`: Workspace projects and directory roots.
   - `session_v2`: Top-level conversation sessions, active agent/model, token usage counts, costs.
   - `session_message`: Message headers, timestamps, and sequence numbers.
   - `session_part`: Granular message chunks (text, reasoning, tool invocations, tool results).
   - `blob` and `blob_ref`: Binary attachments, images, and large diff chunks stored by content SHA-256 hash.
   - `permission`: Saved permission decisions across projects and resources.
   - `credential`: Encrypted and plaintext provider credentials and OAuth tokens.
   - `event`: Append-only event log for durable event sourcing.
4. **CLI & Desktop Sharing**:
   - The CLI (`opencode`) and Desktop GUI share the exact same database file and schema. A single service coordinates concurrent connections, preventing SQLite locking contention.

---

## 6. Providers & Authentication

1. **Supported Providers**:
   - Anthropic, OpenAI, Google Gemini, GitHub Copilot, AWS Bedrock, OpenRouter, Groq, Ollama, DeepSeek, Mistral, xAI.
2. **Credential Storage**:
   - Stored in `credential` table in SQLite (`packages/core/src/credential.ts`).
   - Sensitive API keys are persisted locally; OAuth refresh tokens are stored per integration.
3. **OAuth Flows & Native Browser Handoff**:
   - Route: `POST /api/integration/{id}/connect/oauth` generates state and opens an external browser window via `FilesOpenBrowser` / `FilesOpenExternal`.
   - Local callback: Server listens on `http://127.0.0.1:<port>/auth/connect/{code}` or handles custom protocol redirect (`opencode://auth/...`).
   - The desktop shell forwards deep link URLs to the renderer via `AppConsumeInitialDeepLinks` and `DeepLinksOpened` event stream.

---

## 7. Process & Filesystem Operations

The server spawns and manages multiple external processes:
1. **PTY Shells**: Uses `packages/process-daemon` (native Rust binary `opencode-pty`) or `@lydell/node-pty` for terminal sessions.
2. **Git Executable**: Discovers host `git` (`packages/core/src/util/git-executable.ts`) to compute diffs, list branches, and inspect worktrees.
3. **Ripgrep**: Bundles or discovers `rg` for high-performance codebase search (`packages/core/src/ripgrep.ts`).
4. **Language Servers (LSP)**: Spawns configured language servers over stdio for workspace diagnostics.
5. **MCP Servers**: Spawns external Model Context Protocol subprocesses (`stdio` transport) or connects via SSE/WebSocket (`packages/core/src/mcp/stdio.ts`).
6. **Filesystem Watching**: Implements recursive filesystem monitoring using native watchers (`packages/core/src/filesystem/watcher.ts`).

---

## 8. Architectural Seams for Rust Replacement

Based on the audit, the system boundaries have clear properties:

### Seam 1: The Desktop Shell (Clean & Narrow — Ideal for Option A)
- **Interface**: The Electron shell interacts with the server solely by:
  1. Spawning `opencode serve --service` as a child process.
  2. Reading `service.json` to obtain `{ url, password }`.
  3. Supplying `{ url }` to the renderer via `AppAwaitInitialization`.
  4. Injecting the `Authorization: Basic ...` header on loopback requests.
- **Verdict**: **Exceptionally clean seam**. A Rust shell (Tauri) can replace Electron main/preload completely without altering the TypeScript server or frontend GUI.

### Seam 2: The HTTP / SSE Public Contract (Clean & Fully Specified — Option B)
- **Interface**: The 138-endpoint HTTP/SSE API documented in `docs/audit/openapi/openapi.json`.
- **Verdict**: Cleanly decoupled over HTTP, but large in surface area. If individual server domains are ported to Rust (Option B), the highest-value isolated seams are:
  1. **Filesystem Search & Watcher** (`/api/fs/*`, ripgrep/watcher integration).
  2. **PTY Process Daemon** (`packages/process-daemon` is already Rust!).
  3. **VCS / Git operations** (`/api/vcs/*`).

### Seam 3: Core Domain & AI Execution (Tightly Coupled to Effect / TypeScript)
- **Interface**: `packages/core` session runner, tool execution, model streaming, and Effect state machines.
- **Verdict**: Tightly coupled to Effect-TS runtime and constantly evolving upstream. Porting this in one go (Option C) would be high risk; preserving the existing server while replacing the shell (Option A) delivers the primary memory and binary-size savings on low-resource machines with minimal migration risk.
