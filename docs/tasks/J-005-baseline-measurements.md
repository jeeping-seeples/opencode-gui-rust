# J-005 — Baseline performance measurements

**Phase:** 1 (Study) · **Blocked by:** J-001 merged (needs a working or partially working build) · **Rust code allowed:** no

## Goal

Create repeatable scripts that measure the existing Electron app's start-up time, idle memory and CPU, so every later comparison is against numbers, and so the owner can run the same scripts on their own low-resource machine. This evidence feeds ADR-0001.

## Inputs

`docs/audit/01-repo-and-build.md`, upstream's own start-up benchmark if it exists (the desktop README mentions a `bench:startup` script), `scripts/jules-setup.sh`.

## Do

1. Reuse upstream's benchmark where it works. Otherwise write a small script (shell or Node) under `scripts/baseline/` that launches the packaged or built app under `xvfb-run -a`, waits for a defined "ready" signal (state precisely what it is), and records time to ready.
2. Measure idle memory: after the app has been idle N seconds (default 60), sum resident memory across the **whole process tree** (main, renderer, GPU, utility, and any server process). Report per-process and total. Say how you computed it (for example `/proc/<pid>/status` VmRSS vs PSS from `smaps_rollup`) and that shared memory is counted or not.
3. Measure CPU: average CPU over the idle window, and over one scripted representative action if one can be automated; otherwise report idle only and say so.
4. Run each measurement several times (default 5), report min / median / max, and the commands to reproduce.
5. Record the VM's CPU model, core count and RAM, the OS, the app version and the build mode (dev vs packaged). Packaged builds are the fair baseline; say which you measured.
6. Where possible capture screenshots of the main GUI screens under the virtual display (for example with `xwd` or `import`), saved under `docs/audit/baseline/screenshots/`. If the app cannot render in the VM, say why.
7. Write the output as JSON under `docs/audit/baseline/` with a stable schema so Phase 4 can diff Rust vs Electron results.
8. Document how the owner runs it on their own machine, including prerequisites.

## Deliverables

- `scripts/baseline/` (scripts and a short README)
- `docs/audit/baseline/results-vm.json` (and screenshots if achievable)
- `docs/audit/05-baseline.md` (method, results, caveats)
- `docs/progress/J-005.md`

## Acceptance criteria

- [ ] Scripts run end to end from a clean checkout following the README (show the log).
- [ ] Two consecutive runs give results of the same order of magnitude; if variance is large, say so and why.
- [ ] Whole-process-tree memory is reported, not just the main process.
- [ ] VM specs are recorded next to every number, with an explicit statement that these numbers are not representative of the owner's hardware.
- [ ] If measurement was impossible (build failed, no rendering), the doc says exactly where it stopped and what is needed to continue.

## Out of scope

Optimising anything, comparing against any Rust code, editing upstream.
