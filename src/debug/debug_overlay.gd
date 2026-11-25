class_name DebugOverlay
extends CanvasLayer
## Developer overlay: a speedometer under the crosshair and a debug panel toggled with F3.
## Reads its parent SUCC through SUCC's public API.

const NO_VALUE: String = "—"
const KEY_LIT_ALPHA: float = 1.0
const KEY_DIM_ALPHA: float = 0.3
## Key box node name -> input action.
const KEY_ACTIONS: Dictionary[String, String] = {
	"KeyW": "forward",
	"KeyA": "left",
	"KeyS": "back",
	"KeyD": "right",
	"KeyJump": "jump",
	"KeyCrouch": "crouch",
}

@export var start_visible: bool = true
@export var show_speedometer: bool = true
@export_range(10, 48) var panel_font_size: int = 18
@export_range(12, 96) var speedometer_font_size: int = 28
## Pixels from the screen centre down to the top of the speedometer.
@export_range(0.0, 400.0) var speedometer_offset: float = 40.0
## Seconds between performance line refreshes.
@export_range(0.05, 2.0) var perf_refresh_interval: float = 0.25
## A hop with more ground ticks than this starts a new chain.
@export_range(0, 10) var max_chain_ground_ticks: int = 0

var tracker: BhopTracker = BhopTracker.new()
var sampler: PerfSampler = PerfSampler.new()
var panel_visible: bool:
	get:
		return _panel.visible

var _player: SUCC
var _process_ms: float = 0.0
var _physics_ms: float = 0.0

@onready var _speedometer: Label = $Speedometer
@onready var _panel: PanelContainer = $Panel
@onready var _stats: Label = $Panel/VBox/Stats
@onready var _keys: HBoxContainer = $Panel/VBox/Keys


func _ready() -> void:
	tracker.max_chain_ground_ticks = max_chain_ground_ticks
	sampler.interval = perf_refresh_interval
	_apply_layout()
	_player = get_parent() as SUCC
	if _player == null:
		push_error("DebugOverlay: parent must be a SUCC.")
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	_player.jumped.connect(_on_jumped)
	_player.landed.connect(_on_landed)
	var respawn: PlayerRespawn = _player.get_node_or_null("Respawn") as PlayerRespawn
	if respawn != null:
		respawn.respawned.connect(_on_respawned)


func _apply_layout() -> void:
	_speedometer.visible = show_speedometer
	_panel.visible = start_visible
	_speedometer.add_theme_font_size_override("font_size", speedometer_font_size)
	_speedometer.offset_top = speedometer_offset
	_speedometer.offset_bottom = speedometer_offset
	_stats.add_theme_font_size_override("font_size", panel_font_size)
	for key: Node in _keys.get_children():
		(key as Label).add_theme_font_size_override("font_size", panel_font_size)


func _on_jumped() -> void:
	tracker.on_jumped(Engine.get_physics_frames(), SpeedUtils.horizontal_speed(_player.velocity))


func _on_landed(_fall_velocity: float) -> void:
	tracker.on_landed(Engine.get_physics_frames())


func _on_respawned() -> void:
	tracker.reset()


func _physics_process(_delta: float) -> void:
	sampler.add_tick()


func _process(delta: float) -> void:
	if sampler.add_frame(delta, Time.get_ticks_usec()):
		_process_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		_physics_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_speedometer.text = str(SpeedUtils.to_ups(SpeedUtils.horizontal_speed(_player.velocity)))
	_stats.text = _build_stats()
	for key_name: String in KEY_ACTIONS:
		var lit: bool = Input.is_action_pressed(KEY_ACTIONS[key_name])
		(_keys.get_node(key_name) as Label).modulate.a = KEY_LIT_ALPHA if lit else KEY_DIM_ALPHA


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func _build_stats() -> String:
	var lines: PackedStringArray = []
	lines.append(_line("vert", "%+d" % SpeedUtils.to_ups(_player.velocity.y)))
	lines.append(_line("state", str(SUCC.MovementState.keys()[_player.movement_state])))
	lines.append(_line("floor", str(SUCC.FloorType.keys()[_player.floor_type])))
	lines.append(_line("crouch", "yes" if _player.crouched else "no"))
	var takeoff: String = NO_VALUE
	if tracker.has_takeoff:
		takeoff = str(SpeedUtils.to_ups(tracker.last_takeoff_speed))
	lines.append(_line("takeoff", takeoff))
	lines.append(_line("hops", str(tracker.hops)))
	var ground: String = NO_VALUE
	if tracker.last_ground_ticks >= 0:
		ground = str(tracker.last_ground_ticks)
	lines.append(_line("ground", ground))
	var gain: String = NO_VALUE
	if tracker.has_gain:
		gain = "%+d" % SpeedUtils.to_ups(tracker.last_gain)
	lines.append(_line("gain", gain))
	var has: bool = sampler.has_sample
	lines.append(_line("fps", "%d" % roundi(sampler.fps) if has else NO_VALUE))
	lines.append(_line("frame", "%.2f ms" % sampler.frame_ms if has else NO_VALUE))
	lines.append(_line("process", "%.2f ms" % _process_ms if has else NO_VALUE))
	lines.append(_line("physics", "%.2f ms" % _physics_ms if has else NO_VALUE))
	lines.append(_line("ticks/s", "%d" % roundi(sampler.ticks_per_second) if has else NO_VALUE))
	return "\n".join(lines)


func _line(label: String, value: String) -> String:
	return "%-8s %s" % [label, value]
