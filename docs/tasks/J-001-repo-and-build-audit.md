# J-001 — Repo, build and version audit

**Phase:** 1 (Study) · **Blocked by:** J-000 (upstream imported) · **Rust code allowed:** no

## Goal

Establish exactly what upstream is, what version we are working against, and how its desktop app is built, run and released, with evidence. Confirm or refute the "ground truth" leads in `AGENTS.md`.

## Inputs

`UPSTREAM_VERSION`, `upstream/` (read-only), `AGENTS.md`.

## Do

1. Read `UPSTREAM_VERSION`. Confirm `upstream/` matches it (for example root `package.json` version).
2. Record the licence(s) and any trademark or branding notes you find. Do not interpret legal meaning; just quote locations.
3. Map the monorepo: list every package with a one-line purpose, and state where each of these lives: the GUI web app (renderer UI), the CLI, the server, the desktop shell.
4. Desktop package (`upstream/packages/desktop`): record framework and versions (Electron, electron-vite, electron-builder, Bun, Node engines), entry points, `package.json` scripts, build outputs and bundled resources.
5. Document the install, dev, build and package procedures exactly as upstream documents them.
6. **Try them in your VM** (use `xvfb-run -a` for anything that opens a window): install dependencies, then build the desktop package. Record for each command: the command, working directory, exit status, duration, and the first error text if it failed. If a failure is environmental (no display, no network, missing system library), say so and what would fix it.
7. List the CI workflows under `upstream/.github/workflows` that concern the desktop app: targets, channels (dev / beta / prod), signing and update-feed steps.
8. Fill in the **Commands** section of `AGENTS.md` with the commands you verified, marking each *verified* or *unverified*. This is the only edit to `AGENTS.md` allowed in any task.
9. List unknowns and questions for the owner.

## Deliverables

- `docs/audit/01-repo-and-build.md`
- `AGENTS.md` (Commands section only)
- `docs/progress/J-001.md` (from `docs/progress/TEMPLATE.md`)

## Acceptance criteria

- [ ] Upstream version/commit stated and matches `UPSTREAM_VERSION`.
- [ ] Monorepo package map covers every top-level package.
- [ ] Every statement cites a path (and line range or symbol), command output or URL.
- [ ] Each build/run command has a recorded outcome from your VM, or an explicit reason it could not run.
- [ ] Commands section in `AGENTS.md` lists only commands marked verified or unverified accordingly.
- [ ] Each "ground truth" lead in `AGENTS.md` is marked confirmed, refuted or unverified in the audit.

## Out of scope

Changing any upstream file, fixing build failures, writing Rust, recommending an architecture.
