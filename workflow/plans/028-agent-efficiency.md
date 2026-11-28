# Agent workflow efficiency
Issue: #28
Status: changes 1–2 merged (89c3d61); First step trial pending

Make the feature loop (Ideas → Implement → playtest → review → fix → merge) need fewer inputs and less idle time, without lowering quality. The owner still approves plans, playtests, OKs every fix round, and decides merges and pushes.

Chosen approach: **B, staged**. Fast checks and a fixed loop first, one feature as a trial, then worktrees and parallel sections.

Owner decisions this plan follows:
1. The OK after the review filter stays.
2. Playtest happens right after the first build, before review.
3. The roadmap moves to independent sections that can run on parallel branches.
4. Codex reviews sandboxed with its hosted tools turned off: Implement runs check.ps1, Codex never escalates (option a).
5. The 3 wall-clock test files run in real time. No test changes.
6. A screenshot script replaces godot-ai for proof screenshots.
7. AGENTS.md stays as it is, with one exception: the line from decision 9.
8. `git push` and `git merge` always ask, through `ask` rules in settings.json.
9. Changing check.ps1's real-time test list counts as a test change and needs the owner's approval (one line in AGENTS.md and REVIEW.md).
10. Under parallel sections, drop the per-feature Teach step and phase 3's one-tech-at-a-time gate. /teach stays available on request.

## Sources and labels

Every judgement names a CS146S note from the owner's study notes and the section it comes from. Notes mix three kinds of material, labelled like this:
- **course**: the lecture slides, transcripts or assigned readings, as summarized in the note.
- **Claude**: AI synthesis or teaching inside the note (Week 7 has no course materials, so those notes are all Claude).
- **docs**: Claude Code documentation the note cites.

Advice from outside the notes is marked **outside** and is not course material. One outside source is used: the `addyosmani/agent-skills` repo (MIT), read on 2026-11-27. Week 10 is not in the notes and supports nothing here.

## Where the time goes (measured)

From session transcripts (Claude and Codex) and commit times. Detailed figures come from one feature (018), so treat them as one sample.

| Step (feature 018) | Time | Owner inputs |
|---|---|---|
| Ideas | 16 min, replies 1–3 min each | 5 |
| Build | ~9 min, then ~10 min of godot-ai editor retries ("Editor is open", "Plugin reloaded") | 3 |
| Codex review r1 | 6.5 min | 2 (start it, switch chats) |
| Fix round | 6 min | 2 |
| Codex review r2 | 4 min | 2 |
| Merge and push | ~10 min | 3 |
| Gaps between steps (playtest, switching chats) | ~10 min, mostly the 11 min between Ideas and Implement | — |
| **Total** | **~72 min** | **~17** |

- check.ps1 takes 140–160 s per run. A build runs it 2–4 times, so it is most of a build. Tests are 136 s of a 163 s run because the movement tests run in real time.
- In feature 018 the last two full check runs came back to back with no code change between them.
- The gaps around each Codex review were only 1–4 min. Moving review into Implement saves inputs more than minutes.
- /implement step 3 (plan mode) never ran in any build transcript. The agent skips it.
- All sessions already run in auto mode, and the desktop app already shows banners for questions and finished tasks. Permission prompts are not the bottleneck; chat switching and hand-offs are.
- Ideas commits landed on a feature branch (`Update ideas.md` in `fix/013-slope-stick`), because both chats share one folder.

## Rule audit

Verdicts: **follows**, **conflicts**, **not covered** by the notes.

| # | Rule (file) | Verdict | Note, section (label) | Action |
|---|---|---|---|---|
| A1 | Run check.ps1 after every step, must pass (AGENTS.md) | follows, but the check is slow | Agent-Ready Codebases, Setup checklist 1 and "Small steps beat one big check" (course). Speed conflicts with "Fast checks beat slow ones" (course) | Change 1 |
| A2 | Show proof: test output, screenshot (AGENTS.md) | follows | Agentic Code Review, Before you commit 1 (course reading); Software Factory, step 3 (course reading) | Change 3 changes the tool, not the rule |
| A3 | Never edit or delete a test to pass (AGENTS.md) | not covered directly; doesn't cover the new real-time list | Closest: Agent-Ready Codebases, checklist 6, tests must fail when code is wrong (course) | Change 1 adds one line (decision 9) |
| A4 | Godot path and one-test command (AGENTS.md) | follows | Customizing Your Agent, "What to include: Commands" (course reading, Factory docs) | Keep |
| A5–A6 | Godot 4 APIs only; static types (AGENTS.md) | follows; already enforced by check.ps1 typecheck | Customizing Your Agent, HumanLayer quote on linters (course reading). Agent-Ready Codebases, Basis "default-no" would cut duplicates (course reading) | Keep (decision 7) |
| A7–A8 | One tech per file; feel values as @export (AGENTS.md) | follows | Customizing Your Agent, "Conventions" (course reading) | Keep |
| A9 | Work only on what the plan lists (AGENTS.md) | follows | Plan Before You Build (RePPIT), "Out of scope" (course) | Keep |
| A10 | Never edit addons/ (AGENTS.md + deny rule) | follows, enforced | Instructions vs Permissions (Claude, docs) | Keep |
| A11 | No addons or downloads without asking (AGENTS.md) | follows | Secrets and Security Scanning, "install only dependencies you need" (Claude) | Keep |
| A12 | Layout section (AGENTS.md) | notes disagree | Customizing Your Agent, "Repository map" (Factory docs) vs Agent-Ready Codebases, "Instruct, don't describe" (Basis) | Keep (decision 7) |
| A13 | Naming and commit conventions (AGENTS.md) | not covered | Project convention | Keep |
| C1 | CLAUDE.md imports AGENTS.md | follows | Customizing Your Agent, "What Claude Code reads" (docs) | Keep |
| C2 | Use godot-ai `editor_screenshot` for proof (CLAUDE.md) | not covered; causes repeated retries, and in a worktree it controls the wrong checkout | Software Factory, step 5, turn a repeated correction into a rule, hook or test (course reading) | Changes 3 and 6 |
| S1 | Deny reading `.env` (settings.json) | follows, best-effort | Secrets and Security Scanning, "Block Claude from reading the file" (Claude, docs) | Keep |
| S2 | Deny edits in addons/ (settings.json) | follows | Instructions vs Permissions (Claude, docs) | Keep |
| S3 | Format hook after every edit (settings.json, format-hook.ps1) | follows | Customizing Your Agent, Hooks (course) and HumanLayer quote (course reading) | Keep |
| I1 | Fresh Implement chat per plan (/implement) | follows | Plan Before You Build (RePPIT), clear context after choosing (course); Context Window, `/clear` plus a plan file (Claude) | Keep |
| I2 | Branch from main in the shared folder (/implement step 2) | not covered; caused cross-branch commits | Software Factory, step 7, worktrees separate files (course reading) | Change 6 |
| I3 | Plan mode, wait for OK (/implement step 3) | conflicts in practice: never executed, and the plan is already approved | Instructions vs Permissions (an instruction, not enforced) (Claude); Software Factory, step 2, approve one short spec (course reading) | Change 2: remove |
| I4 | Step by step, check and commit each step (/implement) | follows | Agent-Ready Codebases, "Small steps" (course); Agentic Code Review, step 7 "Commit often" (course reading) | Keep |
| I5 | Test first, watch it fail (/implement) | follows | Agent-Ready Codebases, checklist 3 (course) | Keep |
| I6 | Commits, push and PRs: commit without asking, never offer push or PR (/implement, recent) | follows | Agentic Code Review, step 7 and "What stays your job" (course reading) | Keep as written |
| I7 | Merge and push only when the owner says so (/implement Merge) | follows in intent; instruction-only | Instructions vs Permissions, enforce what must never happen (Claude) | Change 2: `ask` rules (decision 8) |
| I8 | Fix round: run review-filter (/implement) | follows | Agentic Code Review, step 5 filter pass (Claude, not course) | Keep |
| I9 | Show kept and minor findings, wait for OK (/implement) | not covered | Owner rule. Software Factory, humans at a few gates (course reading) | Keep (decision 1) |
| I10 | After round 3, open items go to the owner (/implement, review skill) | follows | Agentic Code Review, step 6 cap at three (course reading) | Keep |
| I11 | Plan wrong → stop; tests change only with approval (/implement) | follows | Plan Before You Build (RePPIT) (course); Task Context (Claude) | Keep |
| D1 | Ideas reads design.md and its state file at start | follows | Context Window, "What carries over" (Claude, docs) | Keep |
| D2 | Triage: small, vague, big, bug (/ideas) | follows | Software Factory, step 1 (Claude's phrasing of the course triage step); RePPIT, "Match effort to size" (course) | Keep |
| D3 | Grill until no questions left (/ideas) | follows; questions already come in batches | Grilling Before You Build, frontier rounds (course reading) | Keep |
| D4 | Research: describe code only; parallel subagents for outside facts (/ideas) | follows | RePPIT, Research (course); Customizing Your Agent, Subagents (course); Always-On Agents, heavy work to helpers (Claude) | Keep |
| D5 | Two proposals, wait for pick (/ideas) | follows | RePPIT, Propose (course) | Keep |
| D6 | Plan template with sliders, tests, out of scope (/ideas) | follows | RePPIT, Plan (course); Software Factory, step 2 and Warp spec prompt (course reading) | Keep |
| D7 | Issue via `gh` only on the owner's account; never the GitHub MCP connector (/ideas) | not covered directly | Owner rule. Close: Background Agents, step 9, work under your own account (course reading) | Keep |
| D8 | Commit the plan on approval (/ideas) | not covered; lands on whatever branch the shared folder is on | Software Factory, step 7 (course reading) | Change 6 fixes the folder |
| R1 | Fresh-eyes review on a different model (review skill) | follows | Agentic Code Review, steps 2 and 8 (course reading; the bug-rate figure is the vendor's claim) | Keep |
| R2 | Reviewer reads plan, AGENTS.md, REVIEW.md | follows | Agentic Code Review, step 3 (course reading) | Keep |
| R3 | Rounds 2–3 review only the new diff | follows | Agentic Code Review, step 6 (course reading; the note's wording reads looser than the source) | Keep |
| R4 | Reviewer runs check.ps1 or says it can't | not covered directly | Closest: Agentic Code Review, step 1, but that is about the author showing proof (course reading) | Change 4: uses Implement's result for format and lint |
| R5 | Trace callers; each behaviour line has a test that goes red | follows | Agent-Ready Codebases, checklist 6 (course); Software Factory, Warp review prompt (course reading) | Keep |
| R6 | Failure scenario per finding; drop "Do not flag" items | follows | Agentic Code Review, step 4 and REVIEW.md section (course reading) | Keep |
| R7 | "Will a player hit this?" bar, Minor list (REVIEW.md, review skill, review-filter; recent) | not covered directly; consistent | Agentic Code Review, REVIEW.md section: define what failure means, limit nitpicking (course reading) | Keep as written |
| R8 | Report format with summary and verdict | follows | Agentic Code Review, REVIEW.md section (course reading) | Keep |
| R9 | Reviewer changes no files except its report (review skill) | follows in intent; instruction-only, and Codex can write anywhere in the workspace | Instructions vs Permissions (Claude); Background Agents, step 3, required steps in plain code (course reading) | Change 4: review.ps1 checks it |
| F1 | review-filter: fresh context, changes no files | follows; "changes no files" is instruction-only (it has Bash) | Agentic Code Review, step 5 (Claude); Instructions vs Permissions (Claude) | Keep; low risk |
| K1 | check.ps1: one command, cheap steps first | follows | Agent-Ready Codebases, checklist 1 and "Fast checks beat slow ones" (course) | Change 1 makes it fast |
| K2 | check.ps1 has no venv fallback; fails in a worktree | not covered | Software Factory, step 7 (course reading) | Change 1 |
| P1 | Roadmap principle 3, "One thing at a time", including the Teach step | conflicts with decisions 3 and 10 | Owner rule; Background Agents, slide 15, scale agents step by step (course) | Change 7 |
| P2 | Roadmap phase 3 gate: each tech feels right before the next starts | conflicts with decisions 3 and 10 | Owner rule | Change 7 |
| X1 | Assets: ask before downloads, treat files as untrusted (/assets) | follows | Prompt Injection, rules (Claude) | Keep |
| X2 | Teach: explain code before changing it (/teach) | follows | Agentic Code Review, "What stays your job" (course reading) | Keep |

### Advice in the notes not applied yet

| Advice | Note, section (label) | Worth it solo? |
|---|---|---|
| Turn repeated corrections into a rule, hook or test | Software Factory, step 5 (course reading); Agent Skills, "Mine your own transcripts" (course) | Yes: changes 2 and 3 come from this |
| Enforce what must never happen instead of asking | Instructions vs Permissions (Claude) | Yes: push and merge ask rules (change 2); review.ps1 file check (change 4) |
| Cap retries at two before changing approach | Background Agents, step 4 (course reading, Stripe) | Yes: in the stop rules (change 2) |
| Run required steps with plain code, not by asking the model | Background Agents, step 3 (course reading) | Yes: review.ps1 (change 4) |
| Give a non-interactive run a complete prompt | Background Agents, step 1 (course reading) | Yes: the Codex prompt in change 4 names plan, round, commit and check result |
| Keep the agent's sandbox without a way out | Background Agents, step 8 (course reading); Prompt Injection, three-part check (Claude) | Yes: hosted tools off in change 4 |
| Check the proof yourself | Software Factory, step 9 and Agentic Code Review, "What stays your job" (course reading) | Yes: Implement links the raw Codex report each round (change 4) |
| Measure kept output, not effort | Background Agents, step 7 (course reading) | Yes: the trial's keep-or-undo bar (first step) |
| Notification when the agent needs you | Customizing Your Agent, Hooks (Claude's example) | Partly: the app already notifies. Change 5 |
| Worktrees share caches and app data | Software Factory, step 7 (course reading) | Yes: `%APPDATA%\Godot` and godot-ai editors are shared (change 6) |
| Don't stack checks on small changes | Software Factory, step 6 (course, one slide example) | Maybe: open question 1; weak evidence |
| Route a subagent to a cheaper model | Customizing Your Agent, Subagents (docs, Claude) | Maybe: optional change 9 |
| Don't edit CLAUDE.md or skills mid-session | Always-On Agents, prompt cache (Claude) | Yes, as a habit: start new chats after this plan lands |
| Break a function on purpose to test the tests | Agent-Ready Codebases, checklist 6 (course) | Now and then, by hand |
| Lint on commit | Agent-Ready Codebases, checklist 5 (course) | Low: check.ps1 lints before every commit already |
| `/security-review`, Dependabot, SAST | Secrets and Security Scanning (Claude) | No: no auth, network or third-party packages beyond addons |
| Cloud sessions, agent teams | Background Agents (course, docs) | No: Godot and playtests are local; teams are experimental |

No note looked outdated. One note disagreement (A12) was decided by the owner. Two note wordings could be tightened by the owner: Agentic Code Review step 6 ("after that, review only the new diff" reads as if it starts after round 3), and Background Agents says per-subagent model choice is "not checked" while Customizing Your Agent lists `model` in the subagent header.

## Changes, ranked by time saved against effort

Savings are estimates from one feature (018).

### 1. Fast check.ps1, with a venv fallback
- **Saves:** ~2 min per run, ~6–10 min per feature (build, fixes and review all run it). **Effort:** small.
- **Files:** `workflow/tools/check.ps1`; one line in `AGENTS.md` "Check your work" and one in `workflow/REVIEW.md` "Flag" (decision 9).
- **What:**
  - Run GUT twice: everything except the wall-clock files with `--fixed-fps 128`, then `tests/debug/test_debug_overlay.gd`, `tests/debug/test_hit_markers.gd` and `tests/ui/test_hit_feedback.gd` in real time. Keep that list in one variable with a comment explaining why. GUT has no exclude flag, so build the fixed-fps file list in the script.
  - If `$root\.venv` has no gdformat, use the main checkout's venv (the same fallback `format-hook.ps1` already has).
  - AGENTS.md and REVIEW.md: changing the real-time list counts as a test change and needs the owner's approval; reviewers flag it.
- **Notes:** Agent-Ready Codebases, "Fast checks beat slow ones" (course); Instructions vs Permissions for the list rule (Claude).
- **Verified (scratch copy):** tests went from 134 s to 9 s. Exactly 4 tests fail under fixed fps, all wall-clock, and pass/fail was the same across 3 runs. Movement numbers were compared on one run: all identical to real time. Those 3 files pass in 6.5 s real time. The venv fallback made check.ps1 pass in a worktree (230/230). The review repeated the speed and failure-list results.
- **Not verified:** the combined script itself (~45 s expected).
- **Risk:** a new wall-clock test fails under fixed fps; it fails loudly. A real fixed-timestep bug could be hidden by moving its file to the list; the AGENTS.md and REVIEW.md lines cover this.
- **Test:** run check.ps1 on main. Expect a pass, around 45 s, and 230 tests in total across both runs.
- **Undo:** revert the commit.

### 2. /implement: drop plan mode, add stop rules, no reruns; ask on push and merge
- **Saves:** 0–3 min per build, and avoids silent rule skips. **Effort:** tiny.
- **Files:** `.claude/skills/implement/SKILL.md`; `.claude/settings.json` (`ask` rules).
- **What:**
  - Remove step 3 (plan mode). The approved plan is the gate.
  - Before each commit, check tracked changes only (`git status --porcelain --untracked-files=no`), so Ideas' untracked drafts in the shared folder don't stop the build. Stage only the files each step touched; never `git add -A`. (outside: agent-skills `/build auto`)
  - Besides the existing stops (step 1, Scope), also stop when: a test can't pass after two tries with different fixes, or a step can't be undone with `git revert`. (Background Agents, step 4, course reading; outside: agent-skills `/build auto`)
  - Don't rerun check.ps1 unless code changed since the last green run. (outside: agent-skills anti-rationalization row)
  - settings.json: `"ask": ["Bash(git push *)", "Bash(git merge *)", "Bash(git -C * push *)", "Bash(git -C * merge *)", "PowerShell(git push *)", "PowerShell(git merge *)", "PowerShell(git -C * push *)", "PowerShell(git -C * merge *)"]`. The `-C` forms matter because rules match from the start of the command, and change 6 merges into the main folder from a worktree (`git -C <main folder> merge …`). The /implement Merge step stays; the prompt is the owner's confirmation (decision 8). Rules match command text, so they are best-effort; a PreToolUse hook that returns "ask" for any git push or merge is the sturdier fallback if a form slips through.
  - Keep the "Commits, push and PRs" section as it is.
- **Notes:** Software Factory, steps 2 and 5 (course reading); Instructions vs Permissions (Claude); Secrets and Security Scanning, rules are best-effort (Claude, docs).
- **Verified:** plan mode never ran (transcripts); back-to-back check runs in 018.
- **Verified (docs, per review round 2):** explicit `ask` rules prompt in every mode, auto mode included.
- **Not verified:** a live prompt in this setup, and whether the `PowerShell(...)` rules match `-C` forms like the Bash ones. Test once with a harmless `git merge` and `git -C . merge` on a scratch branch.
- **Risk:** a bad plan builds without a second look. It was already approved in Ideas, and the skill still stops when the plan looks wrong.
- **Test:** next build: no plan-mode stop, one check per step, no unrelated files staged, a push asks.
- **Undo:** revert the commit.

### 3. Screenshot script for proof
- **Saves:** 2–3 inputs and ~5–10 min per build. **Effort:** medium.
- **Files:** new `workflow/tools/screenshot.ps1` (plus a small GDScript helper, location in open question 2); `CLAUDE.md` proof line; `/implement` step 5.
- **What:** launch Godot (not headless) on a given scene with the debug overlay on, wait a fixed number of physics frames, save the viewport to a PNG, quit. Pass `--quit-after <frames>` as a backstop, and kill the process after 60 s and fail loudly. godot-ai stays for interactive editor work.
- **Notes:** Agentic Code Review, step 1 (course reading); Software Factory, step 5 (course reading); Background Agents, step 3 (course reading).
- **Verified:** the godot-ai retries cost inputs in 016 and 018 (transcripts). Codex captured proof PNGs with its own Godot script during the scratch review, so the approach works on this machine.
- **Not verified:** the script; `--quit-after`; whether a windowed Godot run works from a Claude Bash call without focus problems.
- **Risk:** screenshots before the scene settles; a hang (the timeout covers it).
- **Test:** capture the movement course with F3 on; open the PNG; kill-test with a scene that never quits.
- **Undo:** revert; the CLAUDE.md line goes back to godot-ai.

### 4. Review from inside Implement, sandboxed (`review` command)
- **Saves:** ~5 inputs per feature and the chat switching; only a few minutes of clock time (the gaps around reviews were 1–4 min). **Effort:** medium.
- **Files:** new `workflow/tools/review.ps1`; `workflow/tools/check.ps1` (green record and `-IfChanged`, below); `.claude/skills/implement/SKILL.md` (new "Review" section, fix round runs round R+1 by itself); `.agents/skills/review/SKILL.md` (two lines); `.claude/settings.json` (one allow rule, only if auto mode blocks the script).
- **What, after the owner's playtest and "review":**
  1. `review.ps1 <plan> <round>` (plain code):
     - Check that tracked files are clean (`git diff --quiet HEAD`) and record `HEAD`.
     - Run `check.ps1 -IfChanged` (green record, below) and keep the short hash it reports, from `Recorded green: <hash>` or `Already green at <hash>, skipped`. Fail if it fails or reports no hash.
     - Find `codex.exe` from `$env:CODEX`, else by searching `%LOCALAPPDATA%\OpenAI\Codex\bin\*\` (two hash folders exist; one has no codex.exe).
     - Run Codex with its hosted tools off and stdin closed. Codex arguments:
       `exec -s workspace-write -c approval_policy="never" --disable apps --disable plugins --disable computer_use --disable browser_use --disable in_app_browser --disable image_generation -c web_search='"disabled"' -c mcp_servers.node_repl.enabled=false --add-dir "$env:APPDATA\Godot" --add-dir "$env:LOCALAPPDATA\Godot" -C <repo> "<prompt>"`
       The prompt: `$review <plan> round <R>. check.ps1 passed in Implement at <hash>; don't rerun format or lint; run the Godot tests yourself.` `<hash>` is the hash check.ps1 reported.
     - PowerShell has no `<` redirect, so start it with `Start-Process -FilePath $codex -ArgumentList … -RedirectStandardInput <empty temp file> -NoNewWindow -PassThru`, then `Wait-Process -Timeout 900`; on timeout, `Stop-Process` and fail loudly. (From Bash, `< /dev/null` closes stdin.)
     - After Codex ends, fail unless `HEAD` is unchanged and the only change in `git status --porcelain --untracked-files=all` (compared with before) is the new `workflow/reviews/NNN-slug-rR.md`. Leave `workflow/plans/` and `workflow/state/` out of the comparison: until change 6, Ideas may write there during the run.
  2. Implement runs review-filter, shows kept and minor findings with a link to the raw report, and **waits for the owner's OK** (decision 1).
  3. After the fixes and their commit, Implement runs round R+1 by itself and stops at "ready to merge", a disputed finding, or round 3.
  - Review skill additions: before testing, confirm tracked files are clean and `HEAD` is the reviewed commit (outside: agent-skills `code-review-and-quality`). If a check.ps1 result for this commit is given, record it and run only the Godot steps.
  - Implement runs the script in the background and stays idle until it ends.
  - Note: Codex gets write access to `%APPDATA%\Godot`, the same app data the owner's editor uses.
  - **Green record and skip (`check.ps1 -IfChanged`).** Moved here 2026-11-27 from plan 029 (old change 6), so it's built with review.ps1, the only caller that needs it. Reason: in the planned flow (build, commit, proof, playtest, "review"), review.ps1 would run check.ps1 again on the commit Implement just checked. That costs about 45 s per review round and finds nothing new. The check only matters if something was committed after the last green run, for example slider values tuned during the playtest.
    - Behaviour: when check.ps1 passes with nothing uncommitted in tracked files and no untracked files under `src/` or `tests/`, it writes the current commit hash to `.godot/last-green` and prints `Recorded green: <short hash>`. If anything is uncommitted, or any step fails, it doesn't write the file and leaves any old one as it is. `check.ps1 -IfChanged` exits 0 at once, printing `Already green at <short hash>, skipped`, when `.godot/last-green` names the current commit and the tree is clean as above. Otherwise it runs normally.
    - `.godot/` is already in `.gitignore`, and each worktree has its own `.godot/`, so records never mix between branches. Write the record only at the very end, after every step passed. "Clean" means `git status --porcelain --untracked-files=no` is empty and `git ls-files --others --exclude-standard -- src tests` is empty.
    - Add a `-IfChanged` switch to check.ps1 (a `param([switch]$IfChanged)` block at the top). It's the only way the skip happens; a plain `check.ps1` always runs everything.
    - /implement doesn't change for this: its "don't rerun unless code changed" rule stays a judgement call. It may use `-IfChanged`, but nothing requires it.
    - Test (temporary planted files and commits only; undo them, never push them): after a passing run on a clean tree, `.godot/last-green` holds the current hash, and the run printed `Recorded green`. `check.ps1 -IfChanged` then prints `Already green at <hash>, skipped` and exits 0 in about a second. Plant an untracked `src/planted_x.gd`: `-IfChanged` runs fully, and the record isn't rewritten. Make a commit (any tracked change): `-IfChanged` runs fully. Make one step fail (for example a planted untyped `var x = 5` script): the old record stays unchanged. Then review.ps1 passes the reported hash in the Codex prompt (shown in the run's log).
- **Notes:** Agentic Code Review, steps 2, 3 and 8 and "What stays your job" (course reading); Background Agents, steps 1, 3 and 8 and generator-verifier (course); Prompt Injection, three-part check (Claude); Instructions vs Permissions (Claude).
- **Verified (scratch copy):**
  - `codex exec` (CLI 0.171) ran the review skill on feature 018 round 1 and wrote a valid report in 3.7 min, with the same two findings as the real r1 plus two more.
  - Godot ran in the sandbox once the two Godot app-data folders were writable. Python (gdformat, gdlint) was blocked, which is why Implement runs check.ps1.
  - Without the extra flags Codex had Gmail, Sites, web search, image generation, computer use and node_repl tools; with them, none (the review found this; repeated here). The real 018 review in the Codex app used web search.
  - `approval_policy="never"` takes effect (run header), and Codex can't commit (`.git` is read-only in the sandbox), per the review.
- **Not verified:** the run in the real repo; whether `-c web_search='"disabled"'` keeps its quotes under PowerShell 5.1 (Codex should read it as a plain string either way; the first run's tool list must show no web tool); whether auto mode lets Claude run the script without a prompt; whether account tools would have run without approval (not tested on purpose).
- **Risk:** the reviewer trusts Implement for format and lint (mechanical, already on the "Do not flag" list). A Codex CLI update renames flags; the script fails loudly. Don't use `--ignore-user-config`: per the review it drops project trust and falls back to a read-only sandbox.
- **Test:** first step below, plus the green record test above.
- **Undo:** revert; start reviews from a Codex chat again.

### 5. Notifications
- **Saves:** idle minutes when a stop goes unnoticed. **Effort:** tiny.
- **Files:** none in the repo. App setting "Draw attention on notifications" (flash the taskbar), owner's choice.
- **Notes:** Customizing Your Agent, Hooks (Claude's example).
- **Verified:** banners for questions, permission requests and finished tasks are already on; taskbar flash is off. The docs' Windows Notification hook example opens a dialog box, so a hook adds little over the app.
- **Risk:** none. **Test:** next stop flashes the taskbar. **Undo:** turn it off.

### 6. Implement in its own worktree
- **Saves:** no clock time; stops cross-branch commits, and is needed for change 7. **Effort:** medium.
- **Files:** `.gitignore` (add `.claude/worktrees/`); `/implement` step 2 and Merge; `/ideas` step 7 (commit plans on main in the main folder only); `CLAUDE.md` (godot-ai line).
- **What:**
  - Start each Implement chat as a worktree session (the app's worktree option). Ideas stays in the main folder on main.
  - /implement step 2 creates the branch itself: `git switch -c feat/NNN-slug main`. That uses local main (unpushed plans and merges included) whatever the worktree's own base was, and gives the right branch name.
  - Merge from the main folder.
  - CLAUDE.md: in a worktree, use godot-ai only if the editor's project path is this worktree; otherwise use screenshot.ps1.
  - Playtest a worktree with `Godot --path <worktree>`.
- **Notes:** Software Factory, step 7 (course reading).
- **Verified (scratch):** the format hook works in a worktree; check.ps1 passes there with the change 1 fallback (173 s including a fresh import); Godot does not scan a worktree under `.claude/worktrees/` (no cache entries; the review repeated this). The app creates worktrees in `<repo>/.claude/worktrees`, and the app's branch prefix setting is `claude`. The CLI docs say new worktrees branch from the remote's default branch unless `worktree.baseRef` is `"head"`.
- **Not verified:** which base the desktop app uses (step 2 makes it not matter); two Godot editors with godot-ai at once; Git LFS assets in an app-made worktree (present in a manual one).
- **Risk:** each worktree has its own `.godot` cache (first check ~30 s slower). Godot app data is shared between editors.
- **Test:** one feature built in a worktree after an unpushed commit on main, while Ideas commits on main; the branch contains the unpushed commit and branches stay clean.
- **Undo:** revert; build in the main folder again.

### 7. Roadmap sections and parallel branches
- **Saves:** throughput, not babysitting: the owner still playtests and OKs each branch. **Effort:** medium; only after changes 1–6 work.
- **Files:** `workflow/docs/roadmap.md`; `/ideas` (each plan names its section and the shared files it touches).
- **What:**
  - Rewrite principle 3 to sections with file ownership (for example HUD owns `src/ui/`; SFX owns `assets/audio/` and its scripts). Remove "→ you understand it (Teach chat)"; /teach stays available on request (decision 10).
  - Reword the Phase 3 gate: each tech must feel right and pass its tests before it merges, not before the next one starts (decision 10). Principle 5 (fix movement that feels wrong first) stays.
  - Shared files (`project.godot`, `levels/movement_course/movement_course.tscn`, the player scene) are changed by one branch at a time, because `.tscn` merge conflicts are hard.
  - At most two Implement worktrees at once to start; each merges to main on its own.
- **Notes:** Background Agents, slide 15, scale agents step by step, and review is the bottleneck (course); Background Agents, subagents vs teams (course, docs); Software Factory, step 7 (course reading).
- **Verified:** nothing yet beyond change 6.
- **Risk:** two branches both need a shared file; Ideas checks before approving the second plan. Twice the playtests and OKs in flight.
- **Test:** two small features in different sections, built in parallel, merged one after the other, check.ps1 green on main after each.
- **Undo:** revert the roadmap change; go back to one feature at a time.

### 8. Faster typecheck (optional)
- **Moved to #30** (2026-11-27): built on its own as `workflow/plans/030-faster-typecheck.md`. A probe there measured one process at about 2.4 s for 59 scripts.
- **Saves:** ~15 s per check. **Effort:** small to medium.
- **Files:** `workflow/tools/check.ps1`. One Godot process per script takes 19 s for 59 scripts; one process that loads every script would be faster.
- **Notes:** Agent-Ready Codebases, "Fast checks beat slow ones" (course). **Verified:** the 19 s. **Not verified:** the faster version.
- **Undo:** revert.

### 9. review-filter on a faster model (optional)
- **Saves:** maybe a minute per round. **Effort:** tiny (`model:` in `.claude/agents/review-filter.md`).
- **Notes:** Customizing Your Agent, Subagents (docs, Claude). **Not verified:** that verdicts stay as good. Try on one round and compare.
- **Undo:** remove the line.

### Not recommended
- **Ideas effort or speed changes:** measured replies are 1–3 min, questions are already batched, and research already uses subagents.
- **Removing the owner's OK or the playtest gate:** decisions 1 and 2.
- **Codex escalation (`--approve-for-me`), a bypassed sandbox, or `--ignore-user-config`:** decision 4; Prompt Injection (Claude) and Background Agents, step 8 (course reading).
- **Installing the agent-skills pack:** its skills run 250–400 lines each; Customizing Your Agent and Agent-Ready Codebases favour short, owned instructions.

## Expected result

| | Now (018) | After changes 1–6 (estimate) |
|---|---|---|
| Time per feature | ~72 min | ~50–55 min, most of it from changes 1 and 3 |
| Owner inputs | ~17 | ~6–7: approve plan, playtest + "review", OK round 1, OK round 2 if needed, merge, push |
| Inputs between playtest and "ready to merge" | ~8 with chat switches | 1–2 OKs, in one chat |

Estimates from one feature, not measured. The trial below measures them.

## First step: try on one feature

1. Land changes 1 and 2 in one small branch. Run check.ps1 on main; expect a pass in about 45 s. Test that `git merge` and `git -C . merge` both ask.
2. Build the next feature as usual, then playtest.
3. Instead of opening a Codex chat, tell Implement: "review round 1 with codex exec as in 028-agent-efficiency change 4". It runs check.ps1, then the hardened `codex exec` command from change 4 by hand (no script yet; stdin closed with `Start-Process` or Bash `< /dev/null`), confirms the run's tool list has no web tool, then checks that only the report file changed, then runs review-filter and waits for your OK.
4. Record per-step times and inputs for the whole feature.
5. Keep change 4 if: the review rounds need 2 owner inputs or fewer each, Codex asks for nothing, and the report is as good as a Codex-chat review (compare the two finding lists side by side for the same round). Otherwise undo it and go back to Codex chats.
6. If kept, build `review.ps1` and the Implement "Review" section, then change 3, then 5 and 6. Change 7 comes last.

## Open questions

1. Skip review round 2 when round 1's fixes were tiny (for example only a test assertion)? Software Factory, step 6 says not to stack checks on small changes, but it is a single slide example, so weak evidence. Current rule: always run the next round.
2. Change 3: should the screenshot helper live in `workflow/tools/` (Godot ignores it, so it can't use `class_name`) or under `tests/helpers/`?
