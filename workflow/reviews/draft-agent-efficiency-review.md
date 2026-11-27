# Review: draft-agent-efficiency (plan review)
- Plan: workflow/plans/draft-agent-efficiency.md (untracked draft, read 2026-11-27)
- Repo state at review: main at a07fec8, 1 commit ahead of origin/main, only the draft untracked. No files changed except this one.
- Reviewer: Claude (Opus 5.5), with experiments in a scratch copy outside the repo
- Standard: the owner's CS146S notes (Weeks 1–9), read in full before the plan's audit

**Verdict: approve with fixes.** The direction is right and the biggest claim (fast tests with `--fixed-fps`) holds up. But change 4's Codex command is not sandboxed the way owner decision 4 assumes, and a few rules will stop or break the first trial. Fix findings 1–4 before the first step. Findings 5–7 can wait until changes 4 and 6.

## Findings

### 1. Blocker: the Codex reviewer is not "fully sandboxed"
- **Plan section:** change 4 (command), first step 3, owner decision 4, audit row "Keep the sandbox off the network".
- **Evidence:** I ran the plan's flags (`codex exec -s workspace-write -c approval_policy="never"`, CLI 0.171.0-alpha.13.2) in a throwaway repo. Shell network was blocked (curl: could not resolve host) and `.git` was read-only. But the session also had hosted tools that work outside the local sandbox: a web search tool (it returned a live result with no prompt), the ChatGPT apps connector with Gmail (send, forward, delete), Sites (deploy, set environment variables), computer use, and a `node_repl` MCP server. They come from the user-level `~/.codex/config.toml` (plugins, apps, browser and computer-use features on).
- **Note rule:** Prompt Injection, three-part check (Claude), and Background Agents, step 8 (course reading): a sandbox needs no way out. Here the reviewer can read your private account data (Gmail) and send data out (web, email, deploys), with approvals off. The untrusted-text part is small today (it reads your own repo), but plans include outside research and asset files.
- **What goes wrong:** the plan and decision 4 assume the network is cut. It isn't. A bad instruction in a file the reviewer reads could act on your accounts with no prompt. I did not call any account tool to test whether those calls skip approval. Web search did.
- **Smallest fix:** add these flags to the change 4 command and first step 3: `--disable apps --disable plugins --disable computer_use --disable browser_use --disable in_app_browser --disable image_generation -c web_search='"disabled"' -c mcp_servers.node_repl.enabled=false`. Verified: with these flags the tool list is only `functions, clock, collaboration`, the sandbox stays workspace-write, and reasoning effort stays high. Don't use `--ignore-user-config`: in my test it dropped the project trust, and the sandbox fell back to read-only, so Godot couldn't write its cache. Also add `< NUL` (Codex printed "Reading additional input from stdin").

### 2. Should fix: the new "dirty tree" stops will fire on every commit until change 6
- **Plan section:** change 2 (`git status --porcelain`, stop on work the plan didn't make), change 4 (review.ps1 "check that the tree is clean"; review skill "`git status --short` is empty").
- **Evidence:** right now `git status` shows `?? workflow/plans/draft-agent-efficiency.md`, an Ideas draft in the shared folder. Ideas writes `draft-*.md` and `workflow/state/ideas.md` all the time. Change 6, which separates the folders, comes last in the plan's order. Changes 2 and 4 come first.
- **What goes wrong:** during the trial, Implement stops before every commit, and the review refuses to start because of Ideas' files. That adds the babysitting the plan is trying to remove.
- **Smallest fix:** check tracked changes only (`git status --porcelain --untracked-files=no`) and keep "stage only the files this step touched". In review.ps1 and the review skill, compare `HEAD` and use `git diff --quiet HEAD` instead of "status is empty".

### 3. Should fix: the real-time test list is a new way to make a failing test pass
- **Plan section:** change 1 (real-time list in check.ps1) and its risk line ("tests that depend on real time go in the real-time list").
- **Evidence:** confirmed by experiment (below). Any test that fails under `--fixed-fps` passes again if its file is moved into the real-time list. AGENTS.md "Never edit or delete a test to make it pass" and REVIEW.md "Flag: tests edited or deleted" don't cover check.ps1.
- **What goes wrong:** a real movement bug that only shows at fixed timestep gets "fixed" by moving the file to the list. The diff shows only a check.ps1 change, so neither the AGENTS.md rule nor REVIEW.md's flag rule catches it.
- **Smallest fix:** one line each in AGENTS.md "Check your work" and REVIEW.md "Flag": changing check.ps1's real-time list counts as a test change and needs the owner's approval.
- **Owner decision (2026-11-27):** AGENTS.md may take this one line. That makes an exception to owner decision 7 ("AGENTS.md stays as it is"), so the plan should list AGENTS.md under change 1's files and note the exception under decision 7.

### 4. Should fix: push, merge and the reviewer's "change no other files" rule are instructions only
- **Plan section:** change 4 (Implement runs reviews in the background and runs round R+1 by itself), audit rows I6, F1 and R-rows.
- **Evidence:** `.claude/settings.json` denies only `.env` reads and addons/ edits. "Push only when I say so" (/implement Merge) and the review skill's "You change no other files" are instructions only. In my test, Codex in workspace-write could write anywhere in the workspace (`.git` was read-only, so it can't commit).
- **Note rule:** Instructions vs Permissions (Claude): if something must never happen, enforce it. Background Agents, step 3 (course reading): run the required checks with plain code.
- **What goes wrong:** the plan adds unattended stretches (background Codex, Implement continuing to round R+1). Those are exactly the cases where an instruction-only rule can be skipped without you seeing it. A reviewer that "fixes" a test or source file while reviewing would leave the change uncommitted, and nothing checks for that.
- **Smallest fix:** (a) review.ps1, after Codex ends: fail unless `HEAD` is unchanged and the only change is the new report file (`git status --porcelain --untracked-files=all` lists just `workflow/reviews/NNN-slug-rR.md`). (b) Add `"ask": ["Bash(git push:*)", "Bash(git merge:*)"]` to settings.json, so a push or merge always asks (owner approved, 2026-11-27). List settings.json under the change that adds it (change 2 is the natural place), and the /implement Merge step stays as is: the prompt is your merge confirmation. Deny rules match command text, so they are best-effort (Secrets and Security Scanning). I did not verify that an ask rule still prompts in auto mode: test it once.

### 5. Should fix: no time limit on Codex or the screenshot script
- **Plan section:** change 4 ("runs the script in the background… keeps idle until it ends"), change 3 (windowed Godot "quit").
- **Evidence:** the plan's limits are the round cap (3) and the retry cap (2). Neither covers a hung process. A windowed Godot that never reaches its quit call stays open with no end.
- **What goes wrong:** Implement waits forever, which is the idle time the plan is trying to cut, and you only notice when you check.
- **Smallest fix:** a hard timeout in each script, for example 15 min for review.ps1 and 60 s for screenshot.ps1: kill the process, then fail loudly. Also pass `--quit-after <frames>` to the screenshot run as a backstop (I didn't test this flag).

### 6. Should fix (change 6): an app worktree branches from origin, not your local main
- **Plan section:** change 6 ("start each Implement chat as a worktree session").
- **Evidence:** the Claude Code worktrees docs (code.claude.com/docs/en/worktrees) say `worktree.baseRef` defaults to `"fresh"`, which means the remote's default branch. `"head"` uses your local HEAD. Your workflow commits approved plans and merges on local main and pushes later. Today main is 1 commit ahead of origin. The same docs give the branch name as `worktree-<name>`, not `feat/NNN-slug`. The plan says `claude/`, possibly the desktop app's setting. I didn't check the app.
- **What goes wrong:** a worktree started after an unpushed plan commit or merge doesn't have them. /implement step 1 stops on a missing plan, so that case fails loudly. But a build on top of an unpushed earlier feature starts from old code without warning, and the merge back then has conflicts.
- **Smallest fix:** set `"worktree": {"baseRef": "head"}` in `.claude/settings.json`, or have /implement step 2 run `git switch -c feat/NNN-slug main` itself. Check one app-made worktree before relying on it.

### 7. Should fix (change 6): godot-ai can edit the wrong checkout
- **Plan section:** change 6 and change 3 ("godot-ai stays for interactive editor work").
- **Evidence:** CLAUDE.md tells Claude to use godot-ai, which controls *the open editor*. The plan says the server lists each open editor as its own session. An Implement chat in a worktree has no reason to pick the right one. The editor you normally keep open is on the main folder.
- **What goes wrong:** scene edits or screenshots through godot-ai land in the main folder on main, not in the feature branch. That brings back the cross-branch problem change 6 exists to fix.
- **Smallest fix:** one line in CLAUDE.md: in a worktree, use godot-ai only if the editor's project path is this worktree, otherwise use screenshot.ps1.

### 8. Should fix (change 7): the roadmap edit must also drop the Teach step and the phase 3 gate
- **Plan section:** change 7, roadmap principle 3.
- **Evidence:** roadmap principle 3 also contains the Teach step ("you understand it"). Phase 3's gate requires each tech to feel right before the next starts. Change 7 rewrites principle 3 but doesn't mention either. The notes support scaling step by step (Background Agents, slide 15, course). The same note says review is the bottleneck, and change 7 doubles playtests and OKs in flight.
- **Owner decision (2026-11-27):** don't keep the Teach step per feature or phase 3's one-tech-at-a-time gate under parallel branches.
- **What goes wrong:** if change 7 edits only principle 3, the Phase 3 gate in the roadmap table still says one tech at a time. Ideas would then follow two rules that contradict each other.
- **Smallest fix:** change 7 lists two more roadmap edits: remove "→ you understand it (Teach chat)" from principle 3 (/teach stays available on request), and reword the Phase 3 gate so each tech must feel right and pass its tests before it merges, not before the next one starts. Principle 5 (fix wrong-feeling movement first) can stay as it is.

### 9. Question for you: the savings figures are partly double-counted
- **Plan section:** "Where the time goes", "Expected result", change 4 "Saves".
- **Evidence:** the 018 rows add up to about 62 min, not 72. The plan doesn't say what the missing ~10 min is (playtest?). Change 4 claims 10–15 min, but both review rounds took 10.5 min in total, mostly Codex working, and Codex still takes ~3.7 min per round. Part of that time is check.ps1, which change 1 already counts. All figures come from one feature (018). The plan says "estimates, not measured" about the end result only.
- **What goes wrong:** nothing breaks. But "~40–45 min" may not happen, and the trial can't show it, because it has no success bar.
- **Smallest fix:** in first step 4, record per-step times for the trial feature, and set a keep/undo bar in advance (for example: keep change 4 if review rounds need ≤2 owner inputs and the report matches a Codex-chat review). Background Agents, step 7 (course reading) says to measure kept output, not effort.

## Technical claims

| Claim | Status | Evidence |
|---|---|---|
| Real-time tests 134 s → ~9 s with `--fixed-fps 128` | **Confirmed** | Scratch copy: 136 s wall / 134.2 s GUT real time (230/230); 11 s wall / 9.4 s fixed (226/230). `physics_ticks_per_second=128` in project.godot. |
| Exactly 4 failures, all in the 3 wall-clock files | **Confirmed** | `test_perf_lines_fill_in` (debug overlay), `test_marker_is_gone_after_its_lifetime` (hit markers), `test_fade_in_game` and `test_second_hit_keeps_the_first_voice` (hit feedback). |
| Movement numbers identical to real time | **Confirmed** (1 run, not 3) | Diff of movement/weapons/targets/unit output: only stack-trace lines and object ids differ. |
| GUT has no exclude flag | **Confirmed** | GUT 9.7.1 `cli/gut_cli.gd`: only `-gselect`, `-gunit_test_name`, no exclude. |
| Combined check.ps1 ~45 s; venv fallback works in a worktree | Not checked | Same fallback code as format-hook.ps1, which is fine by reading. |
| `-c approval_policy="never"` is the right key | **Confirmed** | The run header shows `approval: never`. |
| Codex sandbox has no network | **Partly wrong** | Shell network blocked; hosted web search and connectors are not (finding 1). |
| Codex can't commit | **Confirmed** | `.git/index.lock` permission denied. |
| codex.exe "under the Codex app's install folder" | Confirmed, but the folder name is a hash | `%LOCALAPPDATA%\OpenAI\Codex\bin\<hash>\codex.exe`. Two hash folders exist and one has no codex.exe, so the script must search for the file, not hard-code a path. |
| Codex wrote a valid 018 review in 3.7 min | Not checked | Did not repeat. |
| Godot doesn't scan `.claude/worktrees/` | **Confirmed** | A broken `.gd` placed there: import exit 0, no cache entries. |
| App creates worktrees in `<repo>/.claude/worktrees` | **Confirmed** (CLI docs) | worktrees docs; the docs also recommend gitignoring it (as change 6 does). |
| Worktree branch prefix `claude/` | Not checked | The CLI docs say `worktree-<name>` (finding 6). |
| Docs' Windows Notification hook opens a blocking dialog | **Confirmed** (mostly) | hooks-guide: a `MessageBox` dialog that may open behind the terminal. That it blocks follows from MessageBox, not from the docs' wording. |
| Auto mode might block the Codex call | Not checked | The permission-modes docs (from a summary of a truncated page) say auto mode blocks third-party agents run with isolation *and* approval disabled. Codex keeps its sandbox, so it may pass. Test once. |
| Transcript figures (plan mode never ran, back-to-back checks, auto mode in all sessions) | Not checked | Transcripts not read. Two "Update ideas.md" commits are in `fix/013-slope-stick`'s history, which is consistent with the cross-branch claim. |
| Screenshot by windowed Godot from Bash | Not checked | The plan marks it unverified too. |

## Notes audit

Spot-checked every cited note section. All cited notes and sections exist, and the course / Claude / docs labels are right with the small exceptions below. The plan doesn't present its outside source (agent-skills) as course material. It is right that Week 1 and Week 7 notes are Claude's teaching.

Advice in the notes the audit missed:
- Instructions vs Permissions applied to push, merge and reviewer writes (finding 4).
- Background Agents, step 1 (course reading): a non-interactive run must get a complete prompt. Codex with approval `never` can't ask, which is fine as planned, but it backs keeping the prompt explicit.
- Software Factory, step 9 and Agentic Code Review, "What stays your job" (course reading): you check the proof yourself. With review inside Implement you see only the filtered findings. Ask Implement to link the raw report each round.
- Agent-Ready Codebases, checklist 5 (course): lint on commit. check.ps1 covers it, so this is low value.

Note issues to flag (the plan didn't decide these silently, but they matter):
- **Agentic Code Review, step 6** says cap at three, "after that" review only the new diff. REVIEW.md and the review skill review only the new diff in rounds 2–3. The note's wording reads as if it applies only after round 3. The repo's rule matches the source's point (reviewers re-flagging old code), so the note wording looks loose. Worth rewording.
- **Background Agents, "smart friend"** says per-subagent model choice is "not checked". **Customizing Your Agent, Subagents** lists `model` in the subagent header (docs). The notes disagree slightly. Change 9 relies on the second. Low stakes.

## Minor, not fixing
- Audit row on subagent model routing labels it "course, docs". In the note it's an unsourced trade-off line, so "docs/Claude" is closer.
- Row R4 cites Agentic Code Review step 1 (the author shows proof) for the reviewer running checks. That's a stretch, but harmless.
- Row D7 "not covered": Background Agents, step 9 (own account, not a bot's) is close.
- Change 2's "Stop and ask only when…" could be read as overriding /implement step 1's stops. Say "also stop when".
- Change 2's no-rerun rule is instruction-only. It's fine as a habit, but check.ps1 could skip itself when `HEAD` equals the last green hash.
- review.ps1 gives Codex write access to `%APPDATA%\Godot`, the same app data the owner's editor uses. Acceptable, but say so.
- The project folder is `Movement aim trainer`, not `Movement aim trainer (Godot)`.
- First step 3 says "by hand (no script yet)". Use the hardened command from finding 1 even then.

## Owner answers (2026-11-27)
1. Finding 8: don't keep the Teach step per feature or the phase 3 one-tech-at-a-time gate under change 7.
2. Finding 4b: yes, add `ask` rules for `git push` and `git merge`.
3. Finding 3: AGENTS.md can take the one line about the real-time list.

Still open: the plan's own open questions 1 and 2. On question 1: Software Factory step 6 is a single slide example, so treat it as weak evidence.

## Couldn't verify
- The combined check.ps1 time, the venv fallback in a real worktree, and the screenshot script (none exist yet).
- Whether the Gmail and Sites connector calls in Codex would run without approval (not tested on purpose).
- Whether Claude's auto mode lets Implement run `codex exec`, and whether an `ask` rule prompts in auto mode.
- The desktop app's worktree base and branch prefix (the CLI docs only).
- The transcript-based timings and inputs.
- godot-ai behaviour with two editors (the server didn't connect in this session).

---

# Round 2 (2026-11-27)
- Plan: revised draft, 284 lines, "Status: draft (revised after review…)"
- Scope: the round 1 findings, plus the new or changed text (decisions 8–10, the change 1/2/4/6/7 edits, the trial's keep bar).

**Verdict: approve with fixes.** All nine round 1 findings and all three owner answers are in the plan correctly. Two small new problems would break the first use of the new parts: the command I suggested in round 1 doesn't run in PowerShell (my mistake), and the `ask` rules miss the way change 6 merges. Both are one-line fixes.

## Round 1 findings
| # | Status | Where |
|---|---|---|
| 1 Codex hosted tools | fixed | decision 4; change 4 command; "Not recommended" |
| 2 Untracked drafts stop commits | fixed | change 2 (`--untracked-files=no`); change 4 (`git diff --quiet HEAD`) |
| 3 Real-time list loophole | fixed | decision 9; change 1 files and risk; row A3 |
| 4 Instruction-only push/merge, reviewer writes | fixed (but see R2-2) | decision 8; change 2 `ask` rules; change 4 file check; rows I7, R9 |
| 5 No timeouts | fixed | change 3 (60 s), change 4 (15 min) |
| 6 Worktree base | fixed | change 6 step 2 branches from local `main` |
| 7 godot-ai wrong checkout | fixed | change 6 CLAUDE.md line; row C2 |
| 8 Roadmap gates | fixed | decision 10; change 7; rows P1, P2 |
| 9 Savings | fixed | gaps row; change 4 "Saves"; estimate cut to ~50–55 min; keep/undo bar in first step 5 |

The labelling fixes from "Minor, not fixing" (subagent model routing, R4, D7, "also stop when") are in too. The two note wording issues are passed to you, not decided (line 131).

## Findings

### R2-1. Should fix: `< NUL` doesn't work in PowerShell
- **Plan section:** change 4, the `codex exec` command (my round 1 suggestion).
- **Evidence:** in Windows PowerShell 5.1, a test command with `< NUL` gives the parse error "The '<' operator is reserved for future use." review.ps1 is a PowerShell script, and in first step 3 Implement runs the command by hand, maybe through the PowerShell tool.
- **What goes wrong:** review.ps1 doesn't parse, and the trial's first hand-run fails.
- **Smallest fix:** start Codex with `Start-Process -FilePath $codex -ArgumentList … -RedirectStandardInput <empty temp file> -NoNewWindow -PassThru`, then `Wait-Process -Timeout 900` and `Stop-Process` on timeout. That closes stdin and gives the 15-minute kill in one place. From Bash, `< /dev/null` works (that's what I used).
- **Also check during the trial:** Windows PowerShell 5.1 mangles embedded double quotes in native arguments, so `-c web_search='"disabled"'` may arrive without its quotes. Codex's help says a value that doesn't parse as TOML is used as a plain string, so it should still work. Confirm in the trial's first run that the run's tool list has no web tool.

### R2-2. Should fix: the `ask` rules miss `git -C <path> merge`, which change 6 invites
- **Plan section:** change 2 (`ask` rules), change 6 ("Merge from the main folder").
- **Evidence:** the Claude Code permissions docs ("What a Bash rule doesn't match") say `Bash(git push *)` does not match `git -C . push origin main`: rules match command text from the start. An Implement chat in a worktree that merges "from the main folder" will most likely run `git -C "<main folder>" merge feat/NNN-slug`. That matches neither rule, so it runs with no prompt. (`cd <main> && git merge` would prompt, because the docs say `cd` into another folder plus git prompts.)
- **What goes wrong:** after change 6, the merge you wanted a prompt for runs silently. Decision 8 doesn't hold in the one place the plan moves merging to.
- **Smallest fix:** add `"Bash(git -C * merge *)"`, `"Bash(git -C * push *)"` and the two `PowerShell(...)` equivalents to the `ask` list. A sturdier option is one small PreToolUse hook that returns `"ask"` for any git command containing ` push` or ` merge`. The hooks docs confirm PreToolUse can return `permissionDecision: "ask"`, and it still prompts in auto mode. The trial's "test that a `git merge` asks" should test the `-C` form too.
- **Can be updated:** the plan's "Not verified: that an `ask` rule still prompts in auto mode" is answered by the docs. The permission-modes page lists explicit ask rules under actions no mode auto-approves. Keep the one live test anyway.

### R2-3. Should fix (small): review.ps1's "only the report changed" check can trip on Ideas
- **Plan section:** change 4, step 1 (status compared before and after); first step 6 order (review.ps1 is built before change 6).
- **Evidence:** until change 6, Ideas works in the same folder. During a 4–7 min Codex run it can write a `draft-*.md` or edit the tracked `workflow/state/ideas.md`. Both show up as "new changes" after the run.
- **What goes wrong:** the review fails with a false alarm, and you rerun it. It's safe (it fails loudly), but it's the babysitting the plan is trying to remove.
- **Smallest fix:** leave `workflow/plans/` and `workflow/state/` out of the before/after comparison. Or check only the game paths (`src/`, `tests/`, `levels/`, `assets/`, `project.godot`, `workflow/tools/`) plus "the report exists".

## Technical claims (round 2)
| Claim | Status | Evidence |
|---|---|---|
| `ask` rules prompt in auto mode | **Confirmed** (docs) | permission-modes, "Actions no mode auto-approves"; permissions, compound-commands section |
| `Bash(git push *)` form is valid; `PowerShell(...)` rules exist | **Confirmed** (docs) | permissions, "Wildcard patterns" and "PowerShell" sections |
| `ask` rules cover every push/merge | **Wrong** for `git -C` | R2-2 |
| `< NUL` closes stdin | **Wrong** in PowerShell | R2-1 (my round 1 error) |
| Everything carried over from round 1 | unchanged | see round 1 table |

## Minor, not fixing (round 2)
- Change 6 step 2 leaves the app's own `claude/...` branch behind in each worktree. Delete it after the merge, or ignore it.
- Change 2's no-rerun rule and "never `git add -A`" are still instruction-only. They're fine as habits.
- The trial's keep bar "as good as a Codex-chat review" is a judgement call. Comparing the finding lists side by side would make it concrete.

## Questions for you
None new. The plan's open questions 1 and 2 are still yours.

## Couldn't verify (round 2)
- The exact argument Codex receives for `-c web_search='"disabled"'` under PowerShell 5.1.
- Whether the `PowerShell(... *)` ask rules match `git -C` forms the same way the Bash rules do (assumed the same).
