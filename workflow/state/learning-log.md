# Learning log

What I've learned in Teach sessions. Newest at the bottom.

## 2026-11-24: Editor viewport vs playtest
- Learned: playtest runs the scene file on disk; the editor shows an in-memory copy, which can go stale after outside edits
- Learned: CSGBox3D = box built from `size`; `transform` origin is its centre (floor at z=-69, depth 200 reaches z=-169)
- Learned: `F` frames the selected node in the 3D viewport
- Shaky: not yet confirmed which cause applied (stale copy vs camera elsewhere)
- Next: read a .tscn node block (transform, size, material) and what the Transform3D numbers mean
