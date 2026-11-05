# J-004 — Native and platform features inventory

**Phase:** 1 (Study) · **Blocked by:** J-001 merged · **Rust code allowed:** no

## Goal

List every desktop-native capability the app provides, which Electron APIs implement it, and what the realistic Rust-side equivalent would be, so Phase 2 can scope a Rust shell honestly.

## Inputs

`upstream/packages/desktop/src/main` and `src/preload`, electron-builder config, `docs/audit/02-ipc-inventory.md` (if merged; otherwise work from the source).

## Do

1. Enumerate features, including at least: window creation and multi-window, window state persistence, title bar and frame style, menus, tray, dock/taskbar behaviour, deep links and custom protocols, single-instance lock, file/folder dialogs, drag and drop, clipboard, notifications, opening external links and files, auto-update (provider, channels, signature checks), crash/error reporting, logging, persistent settings/store, CLI installation or PATH integration, devtools, zoom, spell-check, and any OS-specific code under `process.platform` branches.
2. For each feature record: Electron API(s) used, source path, platform differences, and user-visible behaviour.
3. For each feature propose the Rust-side route **as options**: a Tauri v2 API or plugin, a Rust crate, or "needs custom work". Look up current Tauri documentation to do this, and cite the doc URL; do not rely on memory.
4. Rate each feature: effort (S/M/L), risk (low/med/high), and what could be lost (for example a behaviour that exists only in Chromium).
5. Flag webview-dependent behaviour that may differ between Chromium (Electron) and the system webview (WebKitGTK on Linux, WKWebView on macOS, WebView2 on Windows): CSS features, `Intl`, fonts, drag/drop, clipboard, PDF, devtools.
6. Identify packaging and distribution differences: installers per OS, code signing, auto-update feed, file associations.

## Deliverables

- `docs/audit/04-native-features.md` (table plus notes)
- `docs/progress/J-004.md`

## Acceptance criteria

- [ ] Each feature has a source path and the Electron API used.
- [ ] Each Rust-side route cites a documentation URL, and says "option", not "decision".
- [ ] Effort, risk and potential-loss columns are filled for every row.
- [ ] A separate list names behaviours at risk from the Chromium-to-system-webview change, each labelled as *known*, *inferred* or *unverified*.
- [ ] Platform coverage is explicit: Linux, macOS and Windows each marked read-from-code or verified.

## Out of scope

Implementing anything, choosing between options, editing upstream.
