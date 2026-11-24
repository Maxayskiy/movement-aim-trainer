# Movement aim trainer

First-person movement aim trainer in Godot 4.7.2+ (typed GDScript). Source-style movement on top of the SUCC addon. Vision: docs/design.md. Build order: docs/roadmap.md.

## Check your work
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/check.ps1` after every step. It must pass before you say you're done.
- Show proof: test output, plus a screenshot with debug overlays for anything visual.
- Never edit or delete a test to make it pass. If you think a test is wrong, stop and tell me.

## Rules
- Godot 4 APIs only. Never Godot 3 (KinematicBody, yield, deg2rad, move_and_slide(velocity)).
- Use static types everywhere.
- One movement tech per file in src/player/techs/. Keep player.gd small.
- Every gameplay value that affects feel must be an @export or a settings value, never a hard-coded number.
- Work only on what the plan file lists. List anything else as a follow-up.
- Never edit files in addons/ (third-party code). To change one, copy it into src/ or levels/ first.
- Don't add addons or downloads without asking.

## Layout
src/ code · levels/ scenes · tests/ tests · tools/ check and hook scripts · addons/ third-party, read-only · docs/plans/ feature plans · docs/reviews/ review reports · docs/state/ chat state · research/ research notes

## Review
Reviews follow `.agents/skills/review/SKILL.md` and the rules in REVIEW.md. Reports go to `docs/reviews/<feature>-r<N>.md`.
