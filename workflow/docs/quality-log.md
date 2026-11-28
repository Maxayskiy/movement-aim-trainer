# Quality log
Status: living document

Report-only code quality audits, one section per roadmap phase gate (newest at the bottom). Audits block nothing. Each finding starts as `Status: open`; the owner changes it to `plan #N` (it becomes an issue through /ideas) or `accepted`. An accepted finding isn't reported again unless the code around it changed.

## How to run an audit

Run it in a fresh chat at a phase gate. The first audit runs at the end of phase 2, before phase 3 tech files start. Earlier gates (the phase 1 gate playtest, even if it's held later) don't start the log.

1. **Scope.** The `src/` files changed since the commit named in the newest audit section: `git diff --name-only <hash> HEAD -- src`. If there is no audit section yet, all of `src/`.
2. **Context.** Read AGENTS.md and every earlier finding marked `accepted`.
3. **Check.** Check each file in scope against the smells and project checks below. Each is a judgement call. A rule in AGENTS.md or a decision in a plan wins over a smell. Skip what check.ps1 already enforces (format, lint, types, warnings, complexity).
4. **Write.** Append `## YYYY-MM-DD, phase N gate, commit <short hash>`, a scope line, then one line per finding:
   `Q<n>. file:line. <smell or check>. <problem>. Fix: <suggested fix>. Status: open`
   Number findings on from the last `Q` id in this file.
5. **Patterns.** List any pattern seen in 3 or more places under a `Patterns` line in the section. The owner decides each one once (keep, replace, or make a helper), and one line goes into AGENTS.md.
6. **Stop.** Change no other file. Hand the section to the owner.
7. **Optional, owner only.** The owner may run `/improve-codebase-architecture` afterwards for deepening ideas. If the owner wants any of its candidates kept, the chat adds them to the same section as findings, with `Architecture` as the smell or check.

## Smells

Fowler's code smells (*Refactoring*, ch. 3), as listed in Matt Pocock's `code-review` skill, github.com/mattpocock/skills, commit bbadaa6, MIT. Restated for GDScript.

1. **Mysterious Name**: a name that doesn't say what the thing does or holds → rename it.
2. **Duplicated Code**: the same logic in two or more places → one function that both call.
3. **Feature Envy**: a function that uses another object's data more than its own → move it to that object.
4. **Data Clumps**: the same few values always passed or stored together → one type (a Resource or inner class).
5. **Primitive Obsession**: a plain int, float or String standing in for a game concept → a small type or an enum.
6. **Repeated Switches**: the same `match` or if-chain on the same value in several places → one shared table, or one method per type.
7. **Shotgun Surgery**: one change needs edits in many files → gather what changes together into one script.
8. **Divergent Change**: one script changes for several unrelated reasons → split it.
9. **Speculative Generality**: hooks, parameters or abstractions that no plan needs → delete them.
10. **Message Chains**: long `a.b.c.d` walks through other nodes → one method on the first object.
11. **Middle Man**: a script that mostly forwards calls → call the target directly.
12. **Refused Bequest**: a script that `extends` a class but ignores or overrides most of it → use composition.

## Project checks

1. Work done every frame or tick while nothing it depends on changed.
2. A comment that no longer matches the code.
3. Code that breaks a pattern line in AGENTS.md.
