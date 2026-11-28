# Review: 029-code-quality-checks (#29), round 1

- Plan: `workflow/plans/029-code-quality-checks.md`
- Reviewed commit: `fba28c0cd01f78079463b744c275a8dcf8591a85`
- Diff reviewed: `main...fba28c0cd01f78079463b744c275a8dcf8591a85`
- Reviewer: Codex (GPT-6)
- check.ps1: passed in Implement at the reviewed commit, as reported by the owner. Review ran both Godot test groups independently. Format and lint were skipped at the owner's request.

## Findings

1. **Plan mismatch — the required underscore control cannot pass as written.** `workflow/plans/029-code-quality-checks.md:95`

   Renaming an unused local from `total` to `_total` changed Godot's exit code from 1 to 0. In the full check, `gdlintrc:35` requires an ordinary local name to start with a lowercase letter, so that same fixture fails at lint. For an unused private member, Godot returned exit 1 for both `var _total: int` and `var __total: int`, with “declared but never used in the class.” This leaves the fifth acceptance test without its required passing result. Make the underscore control a one-file Godot check for a local and record the private-member case as an expected error.

## Minor, not fixing

- `workflow/tools/check.ps1:56` — A legal GDScript local named `from` makes gdradon skip the whole file. Godot accepted an 11-branch fixture. The installed converter emits `from = 1`, which Radon rejects as Python syntax. gdradon sends that diagnostic to stderr and returns success, so the gate receives no grade for the file. This can hide a complex function during development and has no direct effect in play.
- `workflow/docs/quality-log.md:8` — The fresh-chat instructions say to audit at a phase gate and omit the specified first gate at the end of phase 2. The roadmap still lists the phase 1 gate playtest in the backlog. Holding that playtest next could trigger the initial audit early. Only the audit schedule is affected.

## Verification

| Godot 4.7.2 / GUT 9.7.1 | Scripts | Passing tests | Assertions |
|---|---:|---:|---:|
| Fixed FPS (128) | 34 | 196 / 196 | 5,060 |
| Real time | 3 | 34 / 34 | 168 |

Both runs printed `All tests passed!` and exited 0. Godot also logged a root certificate store read error on startup in both runs.

- In a temporary project using the reviewed warning settings, unused local, unused private member, unreachable code and shadowed local each exited 1 with `(Warning treated as error.)`. The typecheck enumerates both `src/` and `tests/`.
- Exercised the PowerShell grade parser with sample gdradon records. A and B passed silently, including B (10). C (11) through F failed and printed the file, symbol, grade and score. For the plan's example the output was `src/probe.gd: sample C (12)`. The sandbox denied execution of the venv's Python launcher, so this was a parser check. The full baseline comes from Implement.
- Checked the roadmap entry, all 12 credited smells, all three project checks, first and incremental audit scope, finding IDs and status transitions, and the owner's decision on patterns seen at least three times. The log has no audit entries. All four changed files are in scope. Gameplay, tests, the real-time test list and AGENTS.md have no diff.

## Verdict

fix and run round 2

## Filter result
| # | Verdict | Reason (one line) |
|---|---|---|
| 1 | keep | Confirmed: `gdlintrc:35` (`function-variable-name: '[a-z][a-z0-9]*(_[a-z0-9]+)*'`) rejects `_`-prefixed locals, and an unused private member like `_x` still triggers its warning. So How to test step 2's fifth file can't pass check.ps1, and Behaviour 1's "a `_` prefix silences it" is wrong for members. Fix the plan wording, not the code. |

Kept: 1 of 1. "Minor, not fixing" items weren't filtered.

Owner decision: no code or test changes this round, and no round 2 (its diff would be empty).

## Follow-ups
- Finding 1: after the merge, the Ideas chat rewords plan 029 Behaviour 1 and How to test step 2 (the `_` prefix silences unused locals in Godot only, gdlint rejects them, and it never silences an unused private member).
