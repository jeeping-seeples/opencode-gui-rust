# Audit: Repository, Build and Version Audit (J-001)

## 1. Upstream Identity and Version Verification

- **Repository Source**: Upstream repository is `anomalyco/opencode` (stated in `UPSTREAM_VERSION:1`, `upstream/package.json:115-117`).
- **Ref / Tag**: `v2.2.5` (`UPSTREAM_VERSION:2`).
- **Commit SHA**: `9bbb8ce18c80f099e0e448775f59d965ead40a21` (`UPSTREAM_VERSION:3`).
- **Import Timestamp**: `2026-11-05T12:05:54Z` (`UPSTREAM_VERSION:4`).
- **Root Package Version**: `2.2.5` (`upstream/package.json:5`). Matches `UPSTREAM_VERSION`.
- **Desktop Package Version**: `2.2.5` (`upstream/packages/desktop/package.json:4`). Matches `UPSTREAM_VERSION`.
- **Server Package Version**: `2.2.5` (`upstream/packages/server/package.json:4`). Matches `UPSTREAM_VERSION`.
- **App Package Version**: `2.2.5` (`upstream/packages/app/package.json:3`). Matches `UPSTREAM_VERSION`.

## 2. Licenses, Trademarks, and Branding

- **Repository Root License**: MIT License (`upstream/LICENSE:1-21`).
  - Copyright: `Copyright (c) 2025 opencode` (`upstream/LICENSE:3`).
  - Stated in root `package.json`: `"license": "MIT"` (`upstream/package.json:119`).
- **Desktop Package License**: MIT License (`upstream/packages/desktop/package.json:6`).
- **Sub-package Licenses**:
  - `upstream/packages/process-daemon/LICENSE`: MIT License, `Copyright (c) 2026 James Long`.
  - `upstream/packages/http-recorder/LICENSE`: MIT License, `Copyright (c) 2025 opencode`.
  - `upstream/packages/ui/LICENSE`: MIT License, `Copyright (c) 2025 opencode`.
- **Trademarks and Branding Constraints**:
  - Application name: `"OpenCode"` / `"OpenCode Dev"` / `"OpenCode Beta"` (`upstream/packages/desktop/electron-builder.config.ts:32-34`).
  - Application IDs: `ai.opencode.desktop`, `ai.opencode.desktop.dev`, `ai.opencode.desktop.beta` (`upstream/packages/desktop/electron-builder.config.ts:31`).
  - Author and Homepage: Author `"OpenCode <hello@opencode.ai>"`, Homepage `https://opencode.ai` (`upstream/packages/desktop/package.json:7-11`).
  - Icons and Assets: Identity icons are stored in `upstream/packages/desktop/icons/{dev,beta,prod}` and `upstream/packages/identity/`. Note that `upstream/packages/desktop/icons/README.md` still mentions Tauri icon generation commands (`bun tauri icon -o src-tauri/icons/{environment}`).

## 3. Monorepo Package Map

Upstream is structured as a Bun/Turbo monorepo managed via `workspaces` in `upstream/package.json:40-46` (`packages/*`, `packages/plugins/*`, `services/*`, `packages/console/*`, `packages/stats/*`).

### Locations of Key Architectural Components

- **GUI Web App (Renderer UI)**: `upstream/packages/app` (SolidJS web app exported as library/components to desktop and web) and `upstream/packages/desktop/src/renderer` (renderer entry point mounting `@opencode/app/desktop`).
- **Desktop Shell**: `upstream/packages/desktop` (`src/main` Electron main process, `src/preload` preload bridge script, `electron.vite.config.ts`, `electron-builder.config.ts`).
- **Server**: `upstream/packages/server` (HTTP/SSE server using `@effect/platform-node`, Hono, and `@opencode/core`).
- **CLI**: `upstream/packages/cli` (CLI binary commands `opencode` and `opencode2`, manages daemon service lifecycle).

### Complete Monorepo Package Inventory

| Directory | Package Name | Purpose |
|---|---|---|
| `packages/ai` | `@opencode/ai` | Schema-first AI provider APIs (text, images, streaming) built with Effect. |
| `packages/app` | `@opencode/app` | Core SolidJS web GUI and application UI components, shared between desktop and web. |
| `packages/cli` | `@opencode/cli` | Command-line interface (`opencode`, `opencode2`) and local server lifecycle orchestration. |
| `packages/client` | `@opencode/client` | Auto-generated TypeScript client bindings for the server protocol and RPC. |
| `packages/codemode` | `@opencode/codemode` | Effect-native confined code execution over schema-described tools. |
| `packages/console/app` | `@opencode/console-app` | SolidStart web dashboard / developer console application. |
| `packages/console/resource` | `@opencode/console-resource` | Infrastructure / resource definitions for the console service. |
| `packages/core` | `@opencode/core` | Core business logic, project sessions, persistence, provider integration, and database models. |
| `packages/desktop` | `@opencode/desktop` | Electron desktop wrapper (main, preload, and electron-builder packaging). |
| `packages/effect-drizzle-sqlite` | *(internal)* | Internal helper library/examples for Effect + Drizzle SQLite integrations. |
| `packages/function` | `@opencode/function` | Serverless cloud functions (GitHub integration, sharing API). |
| `packages/gui-plugins` | `@opencode/gui-plugins` | Built-in GUI plugins and extensibility hooks for the desktop and web app. |
| `packages/http-recorder` | `@opencode/http-recorder` | HTTP and WebSocket deterministic traffic record/replay cassettes for testing. |
| `packages/httpapi-codegen` | `@opencode/httpapi-codegen` | Build-time code generator creating Promise and Effect APIs from public schemas. |
| `packages/identity` | *(assets)* | Brand visual assets, icons, and SVG marks for OpenCode. |
| `packages/latex` | `@opencode/latex` | LaTeX rendering and parser plugins for mathematical document presentation. |
| `packages/merman` | `@opencode/merman` | Mermaid diagram rendering plugin and sequence diagram parser. |
| `packages/patchmark` | `@opencode/patchmark` | Markdown parsing and streaming diff/patch chunk formatting. |
| `packages/plugin` | `@opencode/plugin` | Plugin authoring interfaces, SDK, and runtime loader support for V2 plugins. |
| `packages/plugin-browser` | `@opencode/plugin-browser` | Browser automation and web inspection plugin for desktop. |
| `packages/plugins/figma` | `@opencode/plugin-figma` | Figma MCP integration and official Figma skills for OpenCode. |
| `packages/posts` | `@opencode/posts` | Blog/documentation content collections and Astro post components. |
| `packages/process-daemon` | `@opencode/pty` (npm) | Rust-based native persistent PTY daemon (`packages/process-daemon/Cargo.toml`). |
| `packages/protocol` | `@opencode/protocol` | Public wire protocol definitions, schema groups, RPC interfaces, and error schemas. |
| `packages/schema` | `@opencode/schema` | Shared wire and storage schemas, event schemas, MCP definitions, and migrations. |
| `packages/script` | `@opencode/script` | Internal monorepo build and utility scripts (AST transforms, syntax highlighting). |
| `packages/sdk` | `@opencode/sdk` | In-process programmatic host SDK for running OpenCode sessions in TypeScript. |
| `packages/server` | `@opencode/server` | HTTP/SSE server and runtime composition hosting OpenCode services. |
| `packages/session-ui` | `@opencode/session-ui` | UI components for session timelines, message logs, and file presentation. |
| `packages/simulation` | `@opencode/simulation` | Protocol simulation backend, cassette players, and mocked servers for end-to-end tests. |
| `packages/stats/app` | `@opencode/stats-app` | SolidJS dashboard application for service usage and telemetry metrics. |
| `packages/stats/core` | `@opencode/stats-core` | Data modeling and metric aggregators for telemetry stats. |
| `packages/stats/server` | `@opencode/stats-server` | Backend ingestion API for telemetry and statistical reporting. |
| `packages/stories` | `@opencode/stories` | Storybook / component catalog plugin for UI component isolated development. |
| `packages/theme` | `@opencode/theme` | Color themes, syntax tokens, and TUI theme mappings. |
| `packages/tui` | `@opencode/tui` | Terminal User Interface built with `@opentui/core` and `@opentui/solid`. |
| `packages/ui` | `@opencode/ui` | Core design system, UI primitives, icons, and tailwind base styles. |
| `packages/util` | `@opencode/util` | Cross-platform utilities, base64, hash, and environment helper functions. |
| `packages/web` | `@opencode/web` | Public documentation and marketing website built with Astro and Starlight. |
| `services/changelog` | `@opencode/changelog` | Cloudflare Worker rendering `CHANGELOG.md` at `opencode.ai/changelog`. |
| `services/files` | `@opencode/files` | Cloudflare Worker and R2 bucket distribution endpoint for release binaries. |
| `services/update` | `@opencode/update` | Cloudflare Worker serving update manifest feeds for the desktop updater. |
| `services/www` | `@opencode/www` | Main public web portal and documentation deployment. |

## 4. Desktop Package Audit (`upstream/packages/desktop`)

- **Framework & Runtime Versions**:
  - Electron: `44.9.1` (`upstream/packages/desktop/package.json:41`).
  - electron-vite: `6.0.0-beta.1` (`upstream/packages/desktop/package.json:43`).
  - electron-builder: `26.15.7` (`upstream/packages/desktop/package.json:42`).
  - Vite: `8.2.4` (`upstream/packages/desktop/package.json:49`).
  - SolidJS: `solid-js@1.9.17` (`upstream/package.json:84`).
  - Effect: `4.0.6` (`upstream/package.json:69`).
  - Bun engine requirement: Root `package.json` specifies `"packageManager": "bun@1.4.4"`. In the VM, Bun `1.2.14` was used.
  - Node engine: `@types/node@24.12.2`, TypeScript compiler `tsc` (TypeScript `6.0.2` / `@typescript/native@7.1.0-beta`).
- **Entry Points**:
  - Main process entry: `upstream/packages/desktop/src/main/index.ts` (configured in `electron.vite.config.ts:63` input and compiled to `out/main/index.js`).
  - Preload entry: `upstream/packages/desktop/src/preload/index.ts` (compiled to `out/preload/index.cjs` with CJS format, `electron.vite.config.ts:98-106`).
  - Renderer entry: `upstream/packages/desktop/src/renderer/index.html` referencing `src/renderer/index.ts` (compiled to `out/renderer/`).
- **Scripts in `upstream/packages/desktop/package.json:13-23`**:
  - `dev`: `bun run script/dev.ts` — runs local Electron with hot reloading and local server.
  - `build`: `bun run script/build.ts` — copies icons and metainfo, checks/downloads CLI, runs `electron-vite build`, and runs bundle verification.
  - `pack`: `bun run script/pack.ts` — invokes `electron-builder` to package Linux (`AppImage`, `deb`, `rpm`), macOS (`.app` tarball), or Windows (`unpacked` / NSIS).
  - `test`: `bun test --timeout 30000` — runs desktop unit and contract tests.
  - `typecheck`: `bun check --no-script -b`.
  - `typecheck:tsc`: `tsc -b`.
  - `preview`: `electron-vite preview`.
  - `bench:startup`: `bun run script/bench-startup.ts` — measures startup times on packaged builds over CDP.
  - `migration`: `bun run script/migration.ts`.
- **Build Outputs**:
  - `out/main/`: Main process bundle (`index.js` ESM, plus hashed chunk files).
  - `out/preload/`: Preload script bundle (`index.cjs` CommonJS).
  - `out/renderer/`: Renderer web assets (`index.html`, `assets/*.js`, `assets/*.css`, source maps).
  - `dist/desktop/`: Root output from `bun run pack` containing `.AppImage`, `.deb`, and `.rpm` files on Linux.
- **Bundled Resources**:
  - Placed under `resources/` in the packaged application (`resourcesPath`):
    - `opencode-cli`: Bundled standalone CLI binary for the target OS/architecture (downloaded or copied from `packages/cli/dist`).
    - `opencode-cli.version`: Text file containing the exact bundled CLI version (e.g. `0.0.0-dev-787`).
    - `icons/`: PNG and ICO icons for dev/beta/prod channels.
    - `*.metainfo.xml`: Linux AppStream metainfo metadata.
    - `app-update.yml`: Auto-updater update feed configuration for `electron-updater`.

## 5. Upstream Procedures: Documentation vs Verification

### Documented Upstream Procedures
From `upstream/CONTRIBUTING.md:31-50` and `upstream/packages/desktop/README.md:5-24`:
1. **Install dependencies**: `bun install` (from repository root).
2. **Desktop Development**: `bun run dev:desktop` from root, or `cd packages/desktop && bun dev`.
3. **Desktop Build**: `cd packages/desktop && bun run build`.
4. **Desktop Packaging**: `cd packages/desktop && bun run build && bun run pack`.
5. **Desktop Typecheck**: `cd packages/desktop && bun typecheck` or `bun run typecheck:tsc`.
6. **Desktop Tests**: `cd packages/desktop && bun test`.

### Verification in Jules VM (Environment: Ubuntu 24.04 LTS x86_64, 4 vCPUs, 7.8 GiB RAM, Bun 1.2.14, Node 22.22.1)

| Command | Working Directory | Exit Status | Duration | Outcome & Error Text / Fix |
|---|---|---|---|---|
| `bun install --frozen-lockfile` | `upstream/` | 0 | 1m 31s | **Verified**. Installed 1847 packages; ran `packages/core fix-node-pty` postinstall. |
| `bun run build` (first run) | `upstream/packages/desktop` | 1 | 10.08s | **Environmental failure**. Error: `bun: command not found: bunx`. Fix: created symlink `sudo ln -s /usr/local/bun/bin/bun /usr/local/bin/bunx`. |
| `bun run build` (after fix) | `upstream/packages/desktop` | 1 | 42.51s | **Partial Build Succeeded / Script Failed**. `electron-vite build` compiled `out/main`, `out/preload`, `out/renderer` successfully in 29.47s. Then `verifyBundles()` failed on `new SourceTextModule(source)` because Bun 1.2 does not implement `node:vm.SourceTextModule` (requires Bun >= 1.3 or Node). Fix: run `verify-bundles.ts` under Node or upgrade Bun to >= 1.3/1.4. |
| `tsc -b` (`bun run typecheck:tsc`) | `upstream/packages/desktop` | 0 | 21.81s | **Verified**. Passed cleanly with 0 TypeScript errors. |
| `bun run typecheck` | `upstream/packages/desktop` | 1 | 0.02s | **Failed**. Upstream script runs `bun check --no-script -b`, but `bun check` is not a valid subcommand in Bun 1.2. Upstream uses `bun@1.4.4` experimental check. |
| `bun test` | `upstream/packages/desktop` | 1 | 23.31s | **Failed**. Ran 197 tests: 169 passed, 4 skipped, 24 failed. Failures caused by `node:sqlite` unsupported in Bun 1.2 and `jest.advanceTimersByTime` fake timers. |
| `bun run pack` (first run) | `upstream/packages/desktop` | 1 | 3m 35s | **Environmental failure**. Built AppImage and deb, but failed on rpm: `Need executable 'rpmbuild' to convert dir to rpm (sudo apt-get install rpm)`. |
| `bun run pack` (after `apt-get install rpm`) | `upstream/packages/desktop` | 0 | 4m 04s | **Verified**. Generated `dist/desktop/opencode-desktop-linux-amd64.deb` (272 MB), `opencode-desktop-linux-x86_64.AppImage` (326 MB), and `opencode-desktop-linux-x86_64.rpm` (274 MB). |
| `xvfb-run -a upstream/packages/desktop/dist/linux-unpacked/ai.opencode.desktop.dev --no-sandbox` | repository root | 0 (timed out after 10s by design) | 10s | **Verified**. Executed the packaged desktop binary in headless X display. Electron main initialized, spawned Crashpad and local background service `opencode-cli serve --service` at `~/.config/ai.opencode.desktop.dev/cli/0.0.0-dev-787-x64/opencode-cli`. |

## 6. Upstream CI Workflows for Desktop

Workflows in `upstream/.github/workflows` affecting the desktop app:

1. **`check.yml`**:
   - Triggers: Push to `dev`, PRs to `dev` and `beta`.
   - Desktop coverage: Runs `bun run lint`, `bun run typecheck:tsc` (TS 7.1), and `bun run lint:changed HEAD^1` (oxlint anti-slop rules on `packages/desktop` and GUI packages).
2. **`release.yml`**:
   - Triggers: Automated or manual release tagging.
   - Desktop matrix (`build-desktop` job, lines 277-345):
     - Targets: `darwin-x64`, `darwin-arm64`, `windows-x64`, `windows-arm64`, `linux-x64`, `linux-arm64`.
     - Linux host installs `rpm` (`sudo apt-get install -y --no-install-recommends rpm`).
     - Sets `OPENCODE_TARGET`, runs `bun run build` and `bun run pack`.
     - Linux artifacts: `.AppImage`, `.deb`, `.rpm`.
     - macOS artifacts: `.app.tar` (unsigned).
     - Windows artifacts: Unpacked app directory in `app/`.
   - Windows installer job (`build-desktop-windows-installer`, lines 346-384):
     - Uses `OPENCODE_DESKTOP_APP` pointing to prepackaged/signed app, builds NSIS installer `.exe`.
   - macOS signing job (`sign-desktop-macos`, lines 386-440):
     - Invokes `upstream/.github/release/sign-desktop-macos.sh` to sign app bundle inside-out, create zip/dmg, and notarize with Apple.
   - Windows signing job (`sign-windows` & `sign-desktop-windows-installer`, lines 444-546):
     - Signs binaries using Azure Trusted Signing / Authenticode.
   - Desktop publication job (`publish-desktop`, lines 615-635):
     - Invokes `upstream/.github/release/publish-desktop.sh`.
     - Generates `electron-updater` feeds (`desktop.yml`, `desktop-mac.yml`, `desktop-linux.yml`, `desktop-linux-arm64.yml`) containing SHA-512 hashes and file sizes.
     - Uploads release binaries to `opencode.ai/files/bin/$OPENCODE_VERSION/` and registers update artifacts with `services/update`.
3. **`release-dry-run.yml`**:
   - Dry-run mirror of `release.yml` for pull requests and manual triggers, verifying desktop build and packaging across matrix targets without signing or uploading feeds.

## 7. Confirmation or Refutation of Ground Truth Leads (`AGENTS.md`)

| Lead from `AGENTS.md` | Audit Result | Evidence / Citation |
|---|---|---|
| Upstream is `anomalyco/opencode` (previously `sst/opencode`). Desktop app is `packages/desktop`. | **CONFIRMED** | `UPSTREAM_VERSION:1`, `upstream/package.json:116`, `upstream/packages/desktop/package.json:2`. |
| `packages/desktop` is Electron (`src/main`, `src/preload`, `src/renderer`), built with electron-vite and electron-builder, run by Bun. | **CONFIRMED** | `upstream/packages/desktop/package.json:13-23,41-43`; directory structure in `upstream/packages/desktop/src/{main,preload,renderer}`; build script `upstream/packages/desktop/script/build.ts:32`. |
| Upstream used Tauri (`src-tauri/`) before. Removed in PR #25822 but remains in git history as reference. | **CONFIRMED** | Residual references exist in `upstream/packages/desktop/icons/README.md:1-4` (`bun tauri icon -o src-tauri/icons/{environment}`), `upstream/packages/server/src/cors.ts:25` (`tauri://localhost`), and release scripts (`upstream/.github/release/publish-desktop.sh:11` mentions retired Tauri updater feed). |
| Upstream maintainers said opencode server runs embedded in Electron's main process, whereas under Tauri it ran as separate sidecar. | **REFUTED / CORRECTED** | **The server does NOT run in-process inside Electron's main process in upstream v2.2.5.**<br>Inspection of `upstream/packages/desktop/src/main/service/desktop-cli.ts:40-75` and `background-service.ts:35-75` shows that Electron's main process resolves `opencode-cli` (either from `resources/opencode-cli` or `packages/cli`) and executes it as a separate background process (`opencode-cli serve --service`). Furthermore, during headless VM execution, `pgrep -af opencode` confirmed a separate process was spawned: `/home/jules/.config/ai.opencode.desktop.dev/cli/0.0.0-dev-787-x64/opencode-cli serve --service`. The desktop GUI talks to this daemon over an HTTP client (`@opencode/client/service`). |
| Upstream is mid-rewrite ("OpenCode 2.0": new API, Node migration). Treat as moving target and work against pinned snapshot. | **CONFIRMED** | `upstream/CONTRIBUTING.md:41-46` references V2 CLI and new protocol; `upstream/packages/protocol` and `upstream/packages/server` show the new Effect/HttpApi migration; pinned snapshot `UPSTREAM_VERSION` is v2.2.5. |

## 8. Unknowns and Questions for the Owner

1. **Server Architecture Clarification**: The audit revealed that contrary to earlier rumors that OpenCode 2.0 embedded the TypeScript server directly inside Electron's Node main process, `packages/desktop` in v2.2.5 explicitly runs `opencode-cli serve --service` as a detached child process / background daemon, communicating via HTTP/SSE. This significantly simplifies Option A in ADR-0001 (replacing the Electron shell with a Rust shell like Tauri), since the Rust shell only needs to spawn/manage the `opencode-cli` daemon and expose the IPC channel contract to the renderer. Should Phase 2 focus heavily on this sidecar interface?
2. **Packaging Requirements in CI**: Building Linux RPM packages requires the system package `rpm` (`rpmbuild`). Should `scripts/jules-setup.sh` be updated in a subsequent PR to add `rpm` to the apt-get package list so future agent runs don't encounter packaging failures?
3. **Bun Version Compatibility**: Upstream specifies `bun@1.4.4` in `package.json`, whereas the current VM environment has `bun 1.2.14` and lacks `bunx` in PATH by default. Should the setup script also ensure `bunx` is linked and Bun is upgraded?
