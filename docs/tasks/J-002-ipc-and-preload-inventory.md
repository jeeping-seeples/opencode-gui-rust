# J-002 — IPC and preload inventory

**Phase:** 1 (Study) · **Blocked by:** J-001 merged · **Rust code allowed:** no

## Goal

Produce a complete, checkable inventory of the communication contract between the GUI (renderer) and the Electron shell (main process). A Rust shell must implement this contract so the renderer can stay unchanged.

## Inputs

`upstream/packages/desktop/src/{main,preload,renderer}`, `docs/audit/01-repo-and-build.md`.

## Do

1. Find everything exposed to the renderer through the preload script (`contextBridge.exposeInMainWorld` and similar) and record each exposed API name and signature.
2. Find every IPC handler and listener in the main process (`ipcMain.handle`, `ipcMain.on`, `ipcMain.once`) and every main-to-renderer push (`webContents.send`, `win.webContents.send`).
3. For each channel/API record: name, direction, payload shape and types, response shape, error behaviour, the renderer code that calls it (path and symbol), the main-process code that implements it, and its side effects (filesystem, processes, network, OS dialogs, windows).
4. Mark platform-conditional behaviour (`process.platform` branches) and anything that depends on Electron-only APIs.
5. Cross-check: every preload export has a main handler and a renderer caller. List orphans in each direction.
6. Note any non-IPC channels between renderer and shell (custom protocols, `window.location` hooks, local HTTP calls, query-string flags).
7. Produce a machine-readable version for later contract tests.

## Deliverables

- `docs/audit/02-ipc-inventory.md` (human-readable table plus notes)
- `docs/audit/ipc-inventory.json` (one object per channel with the fields in step 3)
- `docs/progress/J-002.md`

## Acceptance criteria

- [ ] A grep-based count of handlers and listeners in `src/main` matches the number of entries in the inventory, or each difference is explained.
- [ ] Every entry has caller and implementation paths.
- [ ] Orphans and platform-specific entries are listed separately.
- [ ] `ipc-inventory.json` parses as valid JSON (show the command you used to check it).
- [ ] Anything dynamic (channel names built at runtime) is flagged as such.

## Out of scope

Redesigning the API, proposing the Rust equivalents (that is J-004 and Phase 2), editing upstream.
