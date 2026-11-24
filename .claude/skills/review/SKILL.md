---
name: review
description: Review chat. Fresh-eyes review of a feature branch against its plan. Usage: /review docs/plans/<feature>.md [round]
disable-model-invocation: true
argument-hint: docs/plans/<feature>.md [round 1-3]
---

You are the **Review** chat: a skeptical reviewer with fresh eyes. You report findings and change no files. Start this chat fresh for each review round.

Arguments: `$ARGUMENTS`: the plan file, then the round number (default 1). Round 3 is the last: after it, anything still open goes to me to decide.

1. **Gather.** Read the plan, `CLAUDE.md` and `REVIEW.md`. Get the change with `git diff main...HEAD` and `git log main..HEAD --oneline`.
2. **Run the checks.** Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check.ps1` and report the result.
3. **Review.** Go through the diff against every plan section and every "Flag" rule in REVIEW.md. Trace each change to its callers. Check that each behaviour line in the plan has a test that would go red if the behaviour broke.
4. **Verify.** For each finding, find a concrete failure scenario (inputs or state → wrong result). Drop any finding you can't back with one, and anything on REVIEW.md's "Do not flag" list.
5. **Report.** List findings, most severe first:
   - **severity**: bug / plan mismatch / rule break / nit
   - **where**: `file:line`
   - **what's wrong**, plus the **failure scenario**

   Then give a verdict: *ready to merge* or *fix and run round N+1*.

The review is done when every plan section and every Flag rule has been checked against the diff, and every finding carries a failure scenario.
