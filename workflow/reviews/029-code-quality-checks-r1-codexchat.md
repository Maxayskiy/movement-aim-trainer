# Review: 029-code-quality-checks (#29), round 1

- Plan: `workflow/plans/029-code-quality-checks.md`
- Reviewed commit: `fba28c0cd01f78079463b744c275a8dcf8591a85`
- Diff reviewed: `308b37a...fba28c0`. The first hash was the tip of main when the feature branched.
- Reviewer: Codex desktop, GPT-6
- check.ps1: passed on a clean copy of the reviewed commit. Godot 4.7.2 typechecked 59 scripts. GUT passed 196 fixed-fps tests and 34 real-time tests, ending with `ALL CHECKS PASSED`.

## Findings

1. **Plan mismatch** — `project.godot:25`. The required passing example for an intentionally unused local fails at lint. Declare `var unused: int = 1` inside a function and Godot's new error recommends the name `_unused`. Apply that rename and Godot's one-file check exits 0, but `check.ps1` exits 1 with `Function-scope variable name "_unused" is not valid (function-variable-name)`. The naming rule at `gdlintrc:35` requires a lowercase letter first. Reconcile the naming rule with the promised escape and rerun the fifth fixture from “How to test.”

2. **Plan mismatch** — `workflow/tools/check.ps1:56`. A valid version of the required 11-branch fixture gets a green check. With an integer accumulator named `score`, the gate prints `src/planted_complex.gd: probe C (12)` and exits 1. Rename just that local and its uses to `from`, a valid GDScript identifier. Format, lint and Godot still accept the script. During conversion to Python, gdradon prints `Cannot process file 'src\planted_complex.gd' due to exception: invalid syntax` to stderr and exits 0. The loop receives no grade for that file, and the full check ends with `ALL CHECKS PASSED`. Make a gdradon file-processing error fail the complexity step and identify the skipped file.

## Minor, not fixing

- `workflow/tools/check.ps1:57` — With the formatter and linter installed but the gdradon launcher missing, PowerShell reports `CommandNotFoundException` and retains the linter's exit code of 0. The same C (12) fixture reached `ALL CHECKS PASSED`. This requires an incomplete developer environment and has no direct gameplay effect.
- `workflow/docs/quality-log.md:8` — The instructions say to audit at a phase gate without naming phase 2 as the first. The roadmap still lists the phase 1 playtest in the backlog, so a fresh chat at that delayed gate could start the log one gate early. This affects the timing of a report-only audit.

## Verification

- Planted four separate scripts and ran the check with all four present. Typecheck listed each file, reported an unused local, an unused private member, code after a return, and a local shadowing a member, respectively. Each diagnostic ended with `(Warning treated as error.)`. The check ended with `FAILED: typecheck`.
- The clean complexity step printed no grades. The 11-branch control printed the file, function, C grade and score without a line number. A second passing run combined a five-branch B in `src/` with an 11-branch C in `tests/`. The complexity step printed neither. Format, lint and typecheck covered both directories.
- Checked the roadmap entry and the empty audit log against the plan. The log covers initial and incremental file scope, accepted findings, sequential IDs, owner decisions, the three-occurrence pattern rule, and the optional architecture review. It includes all 12 credited smells and three project checks.
- The diff contains the four planned files. It changes no gameplay values, addons, tests, real-time test list, per-feature review rules, or AGENTS.md pattern decisions.

## Verdict

fix and run round 2
