class_name HitFeedback
extends CanvasLayer
## Hit marker and hit/kill sounds. A child of the Player root; listens to the
## sibling Rifle's target_hit. Reads config every frame and on every hit.

## Emitted exactly when play() is called on HitSound.
signal hitsound_played
## Emitted exactly when play() is called on KillSound.
signal killsound_played

@export var config: HitFeedbackConfig

var fade: HitMarkerFade = HitMarkerFade.new()

@onready var _view: HitMarkerView = $Marker
@onready var _hit_sound: AudioStreamPlayer = $HitSound
@onready var _kill_sound: AudioStreamPlayer = $KillSound


func _ready() -> void:
	if config == null:
		config = HitFeedbackConfig.new()
	_view.config = config
	var parent: Node = get_parent()
	if parent == null:
		return
	var rifle: Rifle = parent.get_node_or_null("Rifle") as Rifle
	if rifle != null:
		rifle.target_hit.connect(_on_target_hit)


func _process(_delta: float) -> void:
	fade.duration = config.marker_duration
	_view.config = config
	_view.color = config.kill_color if fade.killed else config.hit_color
	var now: float = Time.get_ticks_usec() / 1e6
	_view.alpha = fade.alpha(now) if config.marker_enabled else 0.0
	_view.queue_redraw()


func _on_target_hit(_collider: Object, killed: bool) -> void:
	fade.duration = config.marker_duration
	fade.show(killed, Time.get_ticks_usec() / 1e6)
	if killed and config.killsound_enabled:
		if _play(_kill_sound, config.killsound, config.killsound_volume):
			killsound_played.emit()
	elif config.hitsound_enabled:
		if _play(_hit_sound, config.hitsound, config.hitsound_volume):
			hitsound_played.emit()


## Sets the player up from the config and plays it. False when silent.
func _play(player: AudioStreamPlayer, stream: AudioStream, volume: int) -> bool:
	if stream == null or volume <= 0:
		return false
	player.stream = stream
	player.volume_db = linear_to_db(volume / 100.0)
	player.max_polyphony = config.max_voices
	player.play()
	return true
