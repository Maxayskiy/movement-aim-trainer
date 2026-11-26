# Movement course
Issue: #14
Status: approved

Feature 5b of roadmap phase 1 (movement base). It replaces the SUCC demo course with our own grey-box course: a hub with stations for each thing the movement base must get right. 5a (#12) proved the hull and terrain limits on `BoxShape3D` geometry built in tests. This course uses the same kind of shapes with the same numbers, so those proofs carry over.

**Start after #12 and #13 are merged.** The ledge heights come from #12. The 46° slope slides only with #13's shipped angles. Branch `feat/014-movement-course` from main.

Approach (chosen): **hand-placed pieces.** Every solid piece is a `CourseBox`: a small `@tool` script on a `StaticBody3D` that makes its own `BoxShape3D` and `BoxMesh` from one `size` export. The course scene places about 60 of them by transform, using the map below. You can still drag and edit them in the editor like any level. Ray-cast geometry tests guard the key numbers.

Facts this plan relies on:
- Godot axes: −Z is north, +X is east, Y is up. The floor top is y = 0.
- `CSGBox3D` collision is one trimesh (`ConcavePolygonShape3D`) with internal edges. #12's seam and edge proofs used `BoxShape3D`, so the course uses no CSG.
- SUCC yaws the player body (`addons/SUCC/scripts/succ_camera.gd:122–126`, relative `rotate_object_local`), and `respawn.gd:22` stores the body's start transform. So rotating the Player root sets the spawn facing, and R restores it.
- `workflow/tools/check.ps1` lints and type-checks only `src/` and `tests/`. Game scripts therefore go in `src/`, not `levels/`.
- Shipped `src/player/player_config.tres` has the same gravity (20.32), jump height (1.143) and step height (0.45) as test config T. The gap lengths below depend on these three.

## Behaviour
What the player gets. Lengths in m, speeds in u/s, angles in degrees.

1. **New main scene.** The game starts in `levels/movement_course/movement_course.tscn`. The SUCC demo course is gone. The player stands on the hub pad at the origin, facing west (−X) toward the strafe lane. R, or falling below −30 m, returns them there with zero velocity (existing `respawn.gd`, unchanged).
2. **Layout.** One floor slab, 200 × 200 m, top at y = 0, open edges, no barrier walls. Stations stand around the hub as in the map below. Each one can be reached on foot from the hub.
3. **Strafe lane** (west). Two walls 1 m thick, 22 m tall and 107 m long, 14 m apart centre to centre (13 m clear inside). Open at both ends. The entrance is at the south end (z = 10) and the run goes north. Every 10 m from the entrance (0, 10 … 100) there's a distance number on both inner walls, 2 m up, and a thin white floor line with no collision.
4. **Bhop gaps** (east). A run-up platform 40 m long × 42 m wide, top at 0.6 m, reached by one 0.3 m step along its west side. Past its east edge (x = 60) stand five 6 × 6 m landing blocks, also 0.6 m tall, with these gaps from the edge:

   | Label | Gap | Block centre z |
   |---|---|---|
   | 400 | 7.80 | −18 |
   | 450 | 8.73 | −9 |
   | 500 | 9.66 | 0 |
   | 550 | 10.60 | 9 |
   | 600 | 11.53 | 18 |

   A gap labelled v is the reach of an **edge takeoff** at v − 25 u/s. An edge takeoff means the hull's back face is 5 cm inside the edge and jump is held 1 tick with no other keys. The reach includes SUCC's air step-up, which lifts up to 0.47 m when the hull clips the block's face. So an edge takeoff at v lands on the block, with about 0.47 m to spare. An edge takeoff at v − 50 falls short by about 0.47 m and ends on the floor. Each block's label shows its v.
5. **Seams and edges** (north-west).
   - A 20 × 20 m plateau, top at 1.5529 m (= 6 sin 15°), made of four 10 × 10 m tiles. Running straight across it crosses a seam at 90°. Running diagonally crosses one at 45°. A 15° ramp, 6 m along the slope and 10 m wide, leads up its south side, and another leads down its north side.
   - Beside it, a 10 × 10 m plateau, top at 3.0 m. A 30° ramp leads up its south side (the crest is its top edge), and another leads down its north side.
   - Ramp tops are level with the plateaus (no lip), and ramp bottoms are level with the floor.
6. **Steps** (south). Four 3 × 3 m boxes, 0.30 / 0.44 / 0.46 / 0.60 m tall. The first two can be walked up. The 0.46 and 0.60 boxes block a walk.
7. **Slopes** (south). Four slopes, each 6 m wide and 8 m along the slope, rising south from the floor at 15° / 30° / 44° / 46°. The 15°, 30° and 44° slopes end in a 4 m deep platform level with their top edge. 44° can be walked up. 46° slides you back down.
8. **Ledges** (south). Two 4 × 4 m boxes, 1.563 m and 1.663 m tall: 5 cm under and over #12's standing-jump limit of 1.613 m. A standing jump climbs the first and not the second.
9. **Crouch tunnel** (south). Copied from the demo: 12 m long, 5 m wide inside, with a roof whose underside is 1.016 m up. You get through crouched, not standing.
10. **Surf** (north). The demo's surf wedge, copied with the same local sizes and transforms. Two faces at 53.13° (rise 0.8 over run 0.6) meet in a ridge, and the wedge is 40 m long. Beside it stands an 8.94 m drop ledge, reached by 22 stairs (0.2032 m rise, 1.016 m deep).
11. **Signs.** One Label3D per station: the station name and its key figure (texts below). Fixed, not billboard. 3 m up, facing the hub, text about 1 m tall. Each bhop block has its own smaller label (about 0.4 m) on its west face, facing the platform.
12. **Look.** Every piece uses the grid texture, world-space triplanar, so one checker square is 1 m and the grid lines up across pieces. Each station type has its own tint (table below). The sky, environment and shadowed sun are copied from the demo. The crosshair is unchanged: a `UI/HUD/Crosshair` "+" label with the HUD theme.

### Map
Station positions (centres in x, z; m). Signs are part of each station.

| Station | Where | Footprint x | Footprint z |
|---|---|---|---|
| Hub pad | origin | −5 … 5 | −3 … 3 |
| Strafe lane | west | −87.5 … −72.5 | −97 … 10 |
| Bhop gaps | east | 18 … 77.53 | −21 … 21 |
| Surf | north | −17 … 12.2 | −80 … −24.2 |
| Seams and edges | north-west | −65 … −27 | −56.6 … −25 |
| Crouch tunnel | south | −48 … −42 | 25 … 37 |
| Steps | south | −22.5 … −1.5 | 25 … 28 |
| Ledges | south | 3 … 13 | 25 … 29 |
| Slopes | south | 19 … 55 | 25 … 36.7 |

### Pieces
Every row is a `CourseBox` (centre, size, rotation in degrees) unless it says otherwise. Ramp rows are rotated about X only: a positive angle rises toward −Z, a negative one toward +Z. A ramp's centre comes from `low_edge + along · L/2 − normal · t/2` with thickness t = 0.5, the same formula as `MovementRig.add_ramp`. The script in the appendix prints every number.

**Root:** `Floor` (0, −0.5, 0), size 200 × 1 × 200, floor material. `Hub/SpawnPad` (0, 0.05, 0), 10 × 0.1 × 6, accent. `Player` at (0, 0.11, 0), rotation y = 90 (faces −X).

**Stations/StrafeLane:** `WallWest` (−87, 11, −43.5) and `WallEast` (−73, 11, −43.5), each 1 × 22 × 107, lane material. `Lines/LineDDD` (one per d = 0, 10 … 100): a `MeshInstance3D` (not a CourseBox, no collision), 13 × 0.01 × 0.1 BoxMesh at (−80, 0.005, 10 − d), white unshaded. `Numbers/WestDDD` Label3D at (−86.49, 2, 10 − d), rotation y = 90. `Numbers/EastDDD` at (−73.51, 2, 10 − d), rotation y = −90. Text `d`.

**Stations/Bhop:** `Step` (19, 0.15, 0), 2 × 0.3 × 42. `Platform` (40, 0.3, 0), 40 × 0.6 × 42. `Block400` … `Block600`: 6 × 0.6 × 6 at x = 63 + gap, y 0.3, z from the table (centres x = 70.80 / 71.73 / 72.66 / 73.60 / 74.53). All bhop material. Block labels `Label400` … `Label600` at (60 + gap − 0.01, 0.3, z), rotation y = −90, text "400" … "600".

**Stations/Surf** at (0, 0, −60): copy the demo's `Surf` children (`RampLeft`, `RampRight`, `DropLedge`, `Stair01`–`Stair22` in `levels/test_course/test_course.tscn:195–346`) with their local transforms and sizes unchanged, each as a CourseBox. Ramps get the surf material, and the ledge and stairs get accent. (The demo group sat at y = 0.25 on a 0.25 m floor top. Here the group is at y = 0.)

**Stations/SeamsEdges:**
- `Seam15/TileNW` (−60, 0.7765, −45.7956), `TileNE` (−50, 0.7765, −45.7956), `TileSW` (−60, 0.7765, −35.7956), `TileSE` (−50, 0.7765, −35.7956): each 10 × 1.5529 × 10.
- `Seam15/RampUp` low edge (−55, 0, −25): centre (−55, 0.535, −27.9625), 10 × 0.5 × 6, rotation x = 15. Its top edge is at z −30.7956, y 1.5529.
- `Seam15/RampDown` low edge (−55, 0, −56.5911): centre (−55, 0.535, −53.6286), 10 × 0.5 × 6, rotation x = −15.
- `Edge30/Plateau` (−32, 1.5, −35.1962), 10 × 3 × 10.
- `Edge30/RampUp` low edge (−32, 0, −25): centre (−32, 1.2835, −27.7231), 10 × 0.5 × 6, rotation x = 30. Top edge z −30.1962, y 3.0.
- `Edge30/RampDown` low edge (−32, 0, −45.3923): centre (−32, 1.2835, −42.6692), 10 × 0.5 × 6, rotation x = −30.
- All seams material.

**Stations/Steps:** `Step030`, `Step044`, `Step046`, `Step060` at x = −21 / −15 / −9 / −3, z 26.5, size 3 × h × 3, centre y = h/2. Steps material.

**Stations/Ledges:** `Ledge1563` at (5, 0.7815, 27), 4 × 1.563 × 4. `Ledge1663` at (11, 0.8315, 27), 4 × 1.663 × 4. Ledges material.

**Stations/Slopes** (low edges at z = 25, rising toward +Z, slopes material):

| Node | Centre | Size | Rot x | Top platform (centre, size) |
|---|---|---|---|---|
| `Slope15` | (22, 0.7938, 28.9284) | 6 × 0.5 × 8 | −15 | `Top15` (22, 1.0353, 34.7274), 6 × 2.0706 × 4 |
| `Slope30` | (32, 1.7835, 28.5891) | 6 × 0.5 × 8 | −30 | `Top30` (32, 2.0, 33.9282), 6 × 4.0 × 4 |
| `Slope44` | (42, 2.5988, 28.0510) | 6 × 0.5 × 8 | −44 | `Top44` (42, 2.7786, 32.7547), 6 × 5.5573 × 4 |
| `Slope46` | (52, 2.7037, 27.9585) | 6 × 0.5 × 8 | −46 | none |

**Stations/CrouchTunnel** at (−45, 0, 31): copy the demo's `Crouch` children (`Roof`, `WallLeft`, `WallRight`, `test_course.tscn:174–193`) with local transforms and sizes unchanged. Crouch material.

**Signs** (Label3D, under each station as `Sign`; rotation y makes the text face the hub):

| Station | Position | Rot y | Text |
|---|---|---|---|
| Strafe lane | (−80, 3, 14) | 99.9 | STRAFE LANE / 107 m |
| Bhop | (15, 3, 0) | −90 | BHOP GAPS / 400–600 u/s |
| Surf | (−9, 3, −22) | 22.2 | SURF / 53° |
| Seams and edges | (−44, 3, −20) | 65.6 | SEAMS & EDGES / 15° · 30° |
| Steps | (−12, 3, 22) | 151.4 | STEPS / 0.30 · 0.44 · 0.46 · 0.60 m |
| Ledges | (8, 3, 22) | −160.0 | LEDGES / 1.56 · 1.66 m |
| Slopes | (37, 3, 22) | −120.7 | SLOPES / 15 · 30 · 44 · 46° |
| Crouch tunnel | (−45, 3, 22) | 116.1 | CROUCH TUNNEL / 1.02 m |

"/" is a line break. Sign and lane-number labels use font size 128, pixel size 0.008 (about 1 m tall), and a dark outline. Block labels use font size 64, pixel size 0.006.

### Tints
Each material is a `StandardMaterial3D` with `albedo_texture` = the grid, `albedo_color` = the tint, `uv1_triplanar` and `uv1_world_triplanar` on, and `uv1_scale` (0.125, 0.125, 0.125). The texture is 8 × 8 squares, so one square is 1 m.

| Material | Tint | Source |
|---|---|---|
| floor | (0.588, 0.588, 0.588) | demo `Mat_Gray` |
| accent | (0.74, 0.66, 0.28) | demo `Mat_Accent` |
| steps | (0.58, 0.50, 0.40) | demo `Mat_Stairs` |
| slopes | (0.38, 0.54, 0.42) | demo `Mat_Slant` |
| bhop | (0.62, 0.46, 0.28) | demo `Mat_Bhop` |
| crouch | (0.50, 0.36, 0.52) | demo `Mat_Crouch` |
| surf | (0.32, 0.42, 0.62) | demo `Mat_Surf` |
| lane | (0.36, 0.40, 0.46) | new |
| seams | (0.36, 0.52, 0.56) | new |
| ledges | (0.62, 0.36, 0.34) | new |
| line | white, unshaded, no texture | new |

## Files to touch
New:
- `src/level/course_box.gd`: `@tool`, `class_name CourseBox`, `extends StaticBody3D`.
  - `@export var size: Vector3 = Vector3.ONE` and `@export var material: Material`, each with a setter that reapplies once the node is ready.
  - In `_ready()` it adds two **internal** children (`add_child(node, false, Node.INTERNAL_MODE_FRONT)`, no owner): a `CollisionShape3D` with a new `BoxShape3D` of `size`, and a `MeshInstance3D` with a new `BoxMesh` of `size` and `material_override` = `material`.
  - Internal, unowned children aren't saved, so the course scene stores only each piece's transform, `size` and `material`. Each instance has its own shape and mesh. No `.tscn` for it.
- `levels/movement_course/movement_course.tscn`: the course (Behaviour, Map, Pieces). Root `MovementCourse` (Node3D), with children `WorldEnvironment`, `DirectionalLight3D`, `Player`, `Floor`, `Hub`, `Stations`, `UI/HUD/Crosshair`.
  - Copy the environment, light and crosshair nodes from the demo (`test_course.tscn:7–21`, `:46–51`, `:369–396`).
  - The crosshair's theme becomes `res://assets/ui/hud_theme.tres`.
- `levels/movement_course/materials/<name>.tres`: the 11 materials in the Tints table.
- `assets/textures/grid.png`: a byte copy of `addons/SUCC/demo/texture_06.png` (MIT). Godot writes its `.import` on import.
- `assets/ui/hud_theme.tres`: a copy of `addons/SUCC/demo/demo.tres`.
- `tests/unit/test_course_box.gd`, `tests/movement/test_course_geometry.gd`, `tests/movement/test_bhop_gaps.gd` (see How to test).

Changed:
- `project.godot`: `application/run/main_scene` → the new course.
- `tests/movement/test_course_scene.gd` → renamed `tests/movement/test_movement_course.gd` (`git mv`). **This is a planned spec change, not an edit to make a test pass.**
  - `COURSE_PATH` points to the new course.
  - `test_demo_level_pieces_removed` is replaced by the checks in How to test.
  - `test_main_scene_is_course` and `test_player_is_our_scene` stay.

Deleted:
- `levels/test_course/test_course.tscn` and `levels/test_course/.gitkeep`.

Not touched: `src/player/` (scene, config, respawn), `tests/helpers/movement_rig.gd` (the gap test uses `spawn`, `add_box`, `settle`, `play` as they are), anything in `addons/`.

## Sliders
None. Course sizes are level geometry, not feel values, and no player value changes. `CourseBox.size` and `CourseBox.material` are editor exports for building levels.

## How to test
Tolerances: heights and positions ±1 mm (the geometry is exact), angles ±0.1°, physics as in the rig (speed ±1 u/s, height ±1 cm). Ray casts use `PhysicsRayQueryParameters3D` on the course's `World3D` after two physics frames, excluding the player's RID. "Ray down at (x, z)" starts at y = 50.

- `tests/unit/test_course_box.gd` (Behaviour 12, CourseBox itself):
  - A `CourseBox` with size (2, 3, 4) added to the tree has one internal `CollisionShape3D` whose `BoxShape3D` is (2, 3, 4), and one internal `MeshInstance3D` whose `BoxMesh` is (2, 3, 4) and whose `material_override` is the given material.
  - Changing `size` after ready updates both.
  - Two instances don't share a shape or mesh.
  - `get_child_count()` is 0 and `get_child_count(true)` is 2. So nothing is saved: pack it into a `PackedScene`, instantiate it, and it still has exactly 2 internal children.
- `tests/movement/test_movement_course.gd` (Behaviour 1, 2, 11, 12):
  - The main scene is `res://levels/movement_course/movement_course.tscn`. `res://levels/test_course/test_course.tscn` doesn't exist.
  - `Player` is a `player.tscn` instance at (0, 0.11, 0) and faces −X (its −basis.z within 0.01 of (−1, 0, 0)).
  - `UI/HUD/Crosshair` exists, and its HUD's theme is `res://assets/ui/hud_theme.tres`.
  - The course has no `CSGShape3D`. Every `StaticBody3D` under `Floor` and `Stations` is a `CourseBox` with a material set.
  - `Floor` is 200 × 1 × 200 with its top at y = 0.
  - Each station has a `Sign` Label3D with billboard off and the text from the Signs table. The five block labels read "400" … "600".
- `tests/movement/test_course_geometry.gd` (Behaviour 3–10), all by ray cast on the loaded course:
  - Steps: ray down at each step centre hits y = 0.30 / 0.44 / 0.46 / 0.60.
  - Slopes:
    - Ray down at each slope's midpoint hits a normal 15 / 30 / 44 / 46° from up.
    - Ray down at each top platform's centre hits its rise.
    - Rays 1 cm on either side of each slope's top edge hit rise − 0.01 · tan(angle) on the slope side and rise on the platform side.
  - Ledges: ray down at each centre hits 1.563 / 1.663.
  - Bhop:
    - Ray down at the platform centre and at each block centre hits 0.6.
    - For each block: from the mid-gap point at y = 0.3 (z = block z), a ray toward −X hits the platform face at x_A and a ray toward +X hits the block face at x_B. x_B − x_A equals the table's gap.
    - Ray down at the mid-gap point hits the floor (y = 0).
  - Seams and edges:
    - Rays down 1 m from the 15° plateau centre, one inside each tile, hit 1.5529.
    - Each ramp's midpoint normal is 15° / 30° from up.
    - At each ramp's top edge, a ray 1 cm onto the plateau hits the plateau top, and a ray 1 cm onto the ramp hits top − 0.01 · tan(angle).
    - At each ramp's low edge, a ray 1 cm onto the ramp hits 0.01 · tan(angle), and a ray 1 cm onto the floor hits 0.
  - Crouch tunnel: a ray up from (−45, 0.01, 31) hits the roof at 1.016. Rays toward −X and +X from (−45, 0.5, 31) hit the walls 5.0 apart.
  - Surf:
    - Ray down at the midpoint of each face hits a normal 53.13° from up.
    - Ray down at the drop ledge centre hits 8.9408.
    - Ray down at stair k's centre hits k · 0.2032 (k = 1 … 22).
  - Strafe lane:
    - Ray down at a wall-top centre hits 22.
    - From (−80, 1, −43.5), rays toward −X and +X hit x = −86.5 and −73.5.
    - A ray from (−87, 1, 20) toward −Z hits z = 10, and from (−87, 1, −110) toward +Z hits z = −97.
    - 11 nodes under `Lines`, at z = 10 − d. A ray down at a line hits the floor at y = 0 (lines have no collision).
    - 22 labels under `Numbers`, with text and z matching.
- `tests/movement/test_bhop_gaps.gd` (Behaviour 4, the physics), with config T, rig floor on, and pinned angles:
  - For each gap: `add_box` a platform 20 × 0.6 × 6 whose east face is at x = 0, and a block 6 × 0.6 × 6 whose west face is at x = gap. (Same height as the course; the rig floor is the course floor.)
  - Spawn the player on the platform, facing +X, with its hull's back face 5 cm inside the edge: centre x = −0.05 + 0.4065, feet at 0.61. Then `settle()`.
  - Set `player.velocity` = (v, 0, 0) in m/s. Play 1 tick with jump held, then 150 ticks of no input.
  - Assert the takeoff tick's horizontal speed is v ±1 u/s.
  - At v: the last sample is on FLOOR with feet at 0.6 ±1 cm and x past the block's west face.
  - At v − 50: the last sample has feet at 0 ±1 cm (on the floor) and x before the block's west face.
  - 10 runs, about 15 s more on check.ps1.
- `workflow/tools/check.ps1` passes. #12's and #13's tests pass unchanged: they build their own geometry.
- **Stop-and-report rule** (same as #8, #10, #12, #13): if a measurement is out of tolerance, stop and report measured against expected. Examples: a gap run lands at v − 50, the player doesn't settle on the 5 cm edge strip, or the takeoff tick loses speed. Don't change tolerances, expected numbers, gap lengths or `addons/`. The user decides.
- **Proof:**
  - GUT output for the four new or renamed test files.
  - Screenshots with the debug overlay on (`editor_screenshot`, `source: "game"`): (a) the spawn view from the hub, (b) standing on the bhop platform looking at the five labelled blocks, (c) inside the strafe lane showing the distance numbers.
  - One editor screenshot from above showing the whole course.
- **Playtest** (the user, after merge; not automated): hold W across the 15° plateau's seams straight and diagonally, and watch the speedometer stay at 400. Then:
  - Walk up the 0.44 step; get blocked by the 0.46.
  - Walk up 44°; slide down 46°.
  - Climb the 1.56 ledge with a standing jump, and fail the 1.66.
  - Crouch through the tunnel.
  - Surf from the drop ledge.
  - Clear the 400 gap at top speed with W only.

## Out of scope
- Moving the crosshair into `player.tscn`.
- Number-key teleports to stations, timed linear runs, and run splits (phase 5).
- Gap lengths that follow a retuned config. The gaps are fixed for gravity 20.32, jump height 1.143 and step height 0.45. Making them follow the tuning panel (feature 6) is a later issue.
- Physics tests of the course scene itself beyond the gaps. Steps, slopes, ledges, seams and ramp edges are proven by #12 and #13 on the same shapes, and the geometry tests prove the course uses them.
- Surf numbers and surf-ramp seams ("rampbug"): issue #9. Crouch-jump limit: issue #7.
- Barrier walls, sounds, lighting or art polish, and a skybox other than the demo's.
- Any change to `addons/`, including deleting `addons/SUCC/demo/`.

## Appendix: how the numbers were computed
Python, stepping SUCC's jump arc and air step-up at dt = 1/128 (`succ.gd:479–484`, `:563–593`; config T):

```python
import math
dt = 1/128; g, h = 20.32, 1.143
v0 = math.sqrt(2 * g * h)
y = lambda k: v0 * k * dt - g * (k * dt)**2 / 2   # feet height after k ticks (as #8, #12)
K = max(k for k in range(200) if y(k) >= -0.47)   # 93: last tick a 0.47 m lift still clears

# Air step-up tests the hull at its start-of-tick position, pushed forward by
# motion + 2 * 0.02 m. Takeoff: back face 5 cm inside the edge, so the front face
# starts 0.813 - 0.05 = 0.763 m past it. Rescue holds while front_K reaches
# edge_B - s*dt - 0.04, which gives:
reach = lambda s: 0.763 + 0.04 + s * (K + 1) * dt  # m, s in m/s
gap = lambda v: round(reach((v - 25) * 0.0254), 2)
# 400: 7.80  450: 8.73  500: 9.66  550: 10.60  600: 11.53
# margin at v and miss at v - 50: 25 * 0.0254 * 94/128 = 0.466 m
```

Ramp pieces, the same formula as `MovementRig.add_ramp`:

```python
def ramp(angle, low, L, rises_toward, t=0.5):
    a = math.radians(angle)
    s = -1 if rises_toward == '-Z' else 1
    along = (0, math.sin(a), s * math.cos(a))
    normal = (0, math.cos(a), -s * math.sin(a))
    centre = [low[i] + along[i] * L / 2 - normal[i] * t / 2 for i in range(3)]
    return centre, (angle if s < 0 else -angle)   # rotation x in degrees
```

Sign rotation: `rot_y = degrees(atan2(0 - x, 0 - z))`, so the label's +Z (its readable side) points at the hub.
