# J-003 — Server contract inventory

**Phase:** 1 (Study) · **Blocked by:** J-001 merged · **Rust code allowed:** no

## Goal

Document how the desktop app starts, talks to and stops the opencode server, and the full HTTP/SSE contract the GUI relies on. Any replacement (Rust shell with the existing server, or a Rust-ported server) must satisfy this contract.

## Inputs

`upstream/packages/desktop/src/main`, the server and GUI-app packages identified in `docs/audit/01-repo-and-build.md`.

## Do

1. **Lifecycle.** How is the server started (embedded in the Electron main process, spawned child, or the bundled CLI)? Record: start-up order, readiness/health check, port selection, hostname binding, how credentials or tokens are generated and passed to the renderer, restart/crash handling, shutdown sequence.
2. **Configuration.** Environment variables, config files, their locations per OS, defaults, precedence, migration of old formats. Include data and cache directories.
3. **HTTP API.** If the server generates an OpenAPI/spec, copy the generated spec unmodified into `docs/audit/openapi/` and note how it is produced. Otherwise enumerate routes, methods, request and response shapes from the source. Mark which routes the GUI actually calls (search the GUI app code) versus routes that exist but are unused by the GUI.
4. **Streaming.** SSE and any WebSocket or PTY streams: endpoint, event names, payload shapes, ordering and reconnection behaviour, how interruption/cancellation works.
5. **Persistence.** Where and in what format sessions, messages, snapshots and settings are stored. Is the format shared with the CLI? Is it versioned or migrated?
6. **Providers and authentication.** How LLM provider credentials and OAuth flows work end to end, where secrets are stored, and what the shell must do (for example open a browser, handle a callback URL).
7. **Process and filesystem operations.** What processes the server spawns (shells, language servers, MCP servers, git) and what filesystem watching or access it does.
8. Identify the seams: places where the server's public contract is narrow and clean, and places where shell and server are tightly coupled.

## Deliverables

- `docs/audit/03-server-contract.md`
- `docs/audit/openapi/` (copied spec, only if upstream generates one)
- `docs/progress/J-003.md`

## Acceptance criteria

- [ ] Lifecycle sequence is written step by step with a source reference for each step.
- [ ] Every route called by the GUI is listed; each is marked GUI-used or not.
- [ ] Every streaming event type is listed with payload shape.
- [ ] Storage locations and formats are documented per OS, or marked unverified for OSes you cannot check.
- [ ] A "seams" section lists candidate boundaries with the evidence that makes each narrow or tight.
- [ ] No secrets or real credentials are copied into the docs.

## Out of scope

Running against real provider accounts, changing the API, deciding what gets ported.
