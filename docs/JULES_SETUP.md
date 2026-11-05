# Starting Jules on this project

For the human project owner. Nothing here needs a powerful local machine.

## One-time setup

1. **Import upstream into this repo (runs in GitHub's cloud).**
   GitHub → this repo → *Actions* → **Import upstream snapshot** → *Run workflow*.
   - `repo`: `anomalyco/opencode` (default).
   - `ref`: prefer a **release tag** so the target stops moving. `dev` is the newest code but changes daily, and upstream is mid-rewrite.
   - The workflow copies upstream into `upstream/`, writes `UPSTREAM_VERSION`, and opens a pull request. Merge it.
   - If it fails with "GitHub Actions is not permitted to create pull requests": *Settings → Actions → General → Workflow permissions* → tick **Allow GitHub Actions to create and approve pull requests**, then re-run. (The branch is pushed either way, so you can also open the PR by hand.)
2. **Connect Jules.** Go to https://jules.google.com, sign in with Google, connect GitHub, and select this repository.
3. **Environment setup script.** When creating a task, paste the contents of `scripts/jules-setup.sh` into the optional environment setup box. It installs Bun, Rust, a virtual display and the libraries Electron and Tauri need. It has not been tested against Jules's current base image, so if a step fails, tell Jules in the task or fix the script in a PR.

## Starting a task

1. Pick the repo and the `main` branch.
2. Paste this prompt, changing the task id and file name:

   ```
   Follow AGENTS.md. Do task J-001 exactly as described in
   docs/tasks/J-001-repo-and-build-audit.md. Change only the files listed under
   Deliverables. Do not write Rust code. Do not edit upstream/.
   ```

3. Click **Give me a plan** and read the plan before approving. This is your approval gate. Reject or ask for changes if the plan:
   - edits anything under `upstream/`,
   - writes Rust or changes build tooling,
   - touches files that are not listed under Deliverables,
   - skips the verification steps.
4. Approve. Jules works in the background and notifies you when done or when it needs input.
5. Review the pull request with the checklist below, then merge or request changes.
6. Update the status table in `docs/PROGRESS.md` (agents are told not to edit it, to avoid merge conflicts).

## Order of tasks

1. `J-001` first. Later tasks use its build findings.
2. After J-001 is merged, `J-002`, `J-003`, `J-004` and `J-005` can run at the same time. They write different files.
3. `J-006` after all of those are merged. It produces the audit summary and a proposed ADR-0001.
4. **You then decide ADR-0001** in `docs/DECISIONS.md`. Nothing in `docs/TASKS.md` under "Gated backlog" starts before that.

## Pull request review checklist

- Only the deliverable files changed (and nothing under `upstream/`).
- Claims cite file paths, commands or URLs. Inferred and unverified items are labelled.
- Anything the agent could not run is stated plainly, not papered over.
- `docs/progress/<task-id>.md` exists and lists tests run, known issues and decisions needing approval.
- No secrets, tokens or personal data.

## If Jules struggles

- Tasks are sized for one pull request. If one is too big, ask Jules to do only one numbered step of the "Do" list and open the rest as a follow-up task.
- Usage limits depend on your Jules plan; check https://jules.google/docs for the current limits.
- Jules works in a headless Linux VM. Anything that needs macOS, Windows or a real screen will be reported as unverified. That is expected.
