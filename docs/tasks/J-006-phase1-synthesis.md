# J-006 — Phase 1 synthesis and ADR-0001 proposal

**Phase:** 1 (Study) · **Blocked by:** J-001 to J-005 all merged · **Rust code allowed:** no

## Goal

Turn the five audits into the Phase 1 deliverable, `docs/ARCHITECTURE_AUDIT.md`, and give the owner what they need to decide ADR-0001.

## Inputs

Everything under `docs/audit/`, `docs/progress/`, `docs/DECISIONS.md`.

## Do

1. Replace the skeleton in `docs/ARCHITECTURE_AUDIT.md` with a synthesis: system overview, component map (renderer, preload, main, server, CLI), the communication contract (IPC and HTTP/SSE) in summary form with links to the detailed audits, native feature summary, build and release process, baseline numbers.
2. Where audits disagree or leave gaps, list them explicitly as open questions. Do not smooth them over.
3. Identify migration boundaries: candidate seams ranked by how narrow the contract is and how well it is tested, with evidence for each.
4. Where does the baseline say the resources go? Show the process-tree breakdown. State which layer (shell vs server vs renderer) dominates, and how confident that conclusion is given VM-only measurements.
5. Risk register: technical, compatibility, upstream-drift, licensing, platform coverage.
6. Update the options in ADR-0001 with the evidence: keep it **Proposed**, strengthen or revise each option's for/against, and state which phase-1 facts would change the recommendation. Do not mark it Accepted.
7. Update `docs/TASKS.md` "Gated backlog": adjust task descriptions and ordering to match what the audit found, keeping each task one PR in size. Mark the gate (ADR-0001) unchanged.
8. Tick the Phase 1 checkboxes in `PLAN.md` only where an audit document provides the evidence; leave others unchecked and say why in your report.

## Deliverables

- `docs/ARCHITECTURE_AUDIT.md`
- `docs/DECISIONS.md` (ADR-0001 evidence update only; status stays Proposed)
- `docs/TASKS.md` (Gated backlog section only)
- `PLAN.md` (Phase 1 checkboxes only)
- `docs/progress/J-006.md`

## Acceptance criteria

- [ ] Every claim links to an audit document or a source path.
- [ ] Open questions and conflicts between audits are listed, not resolved by guessing.
- [ ] ADR-0001 is still Proposed and includes the evidence update.
- [ ] Phase 1 checkboxes ticked only with a linked piece of evidence each.
- [ ] The summary is readable by someone who has not read the individual audits (one page for the executive summary).

## Out of scope

Choosing the architecture, writing `docs/RUST_ARCHITECTURE.md`, writing any Rust.
