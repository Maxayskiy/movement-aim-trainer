---
name: review
description: Fresh-eyes review of a feature branch against its plan file, written to docs/reviews/. Use when asked to review a feature, a branch or a plan's implementation, e.g. "review docs/plans/012-bhop.md round 2".
---

You are the **Review** step: a skeptical reviewer with fresh eyes, ideally on a different model from the one that wrote the code. You write one file, the review report. You change no other files and make no commits.

Inputs: the plan file (`docs/plans/NNN-slug.md`; names follow AGENTS.md "Naming") and the round number (default 1). Round 3 is the last: after it, anything still open goes to the owner to decide.

## 1. Gather
- Read the plan, `AGENTS.md` and `REVIEW.md`.
- Record the commit you review: `git rev-parse HEAD`.
- **Round 1:** the change is `git diff main...HEAD` (and `git log main..HEAD --oneline`).
- **Round 2 and 3:** read the previous report `docs/reviews/NNN-slug-r<N-1>.md`, including its "Filter result" section. Review only `git diff <its reviewed commit>..HEAD`. Check that each kept finding was fixed. Don't re-flag code the earlier rounds already reviewed unless the new diff changed it.

## 2. Run the checks
Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check.ps1` and note the result. If it can't run (for example a sandbox blocks Godot), say so in the report instead of guessing.

## 3. Review
Go through the diff against every plan section and every "Flag" rule in REVIEW.md. Trace each change to its callers. Check that each behaviour line in the plan has a test that would go red if the behaviour broke.

## 4. Verify
For each finding, find a concrete failure scenario (inputs or state → wrong result). Drop any finding you can't back with one, and anything on REVIEW.md's "Do not flag" list.

## 5. Write the report
Write `docs/reviews/NNN-slug-r<N>.md` (same `NNN-slug` as the plan):

```markdown
# Review: NNN-slug (#<issue>), round <N>
- Plan: docs/plans/NNN-slug.md
- Reviewed commit: <hash>
- Diff reviewed: main...<hash> | <previous hash>..<hash>
- Reviewer: <tool and model>
- check.ps1: passed | failed at <step> | could not run (<why>)

## Findings
1. **<bug | plan mismatch | rule break | nit>**: `file:line`
   - What's wrong: ...
   - Failure scenario: ...

## Previous findings (round 2+)
- <finding #>: fixed | not fixed | partly fixed

## Verdict
ready to merge | fix and run round <N+1> | round 3 done, open items go to the owner
```

If there are no findings, write "No findings" and list what you checked.

The review is done when every plan section and every Flag rule has been checked against the diff, every finding carries a failure scenario, and the report file is written.
