class_name HitFeedbackConfig
extends Resource
## Hit marker and hit/kill sound values. HitFeedback reads them every frame
## (marker) and on every hit (sounds), so edits apply while the game runs.

## Off: no X is drawn. Sounds are not affected.
@export var marker_enabled: bool = true
## Pixels from the screen centre to each line's start, along the diagonal.
@export_range(0.0, 50.0, 1.0) var marker_gap: float = 8.0
@export_range(1.0, 50.0, 1.0) var marker_length: float = 8.0
@export_range(1.0, 10.0, 1.0) var marker_thickness: float = 2.0
## Outline width in pixels around each line. 0 = no outline.
@export_range(0.0, 5.0, 1.0) var marker_outline: float = 1.0
## Matches the crosshair outline.
@export var marker_outline_color: Color = Color(0.16, 0.16, 0.18, 1.0)
## Seconds from full strength to nothing.
@export_range(0.05, 1.0, 0.01) var marker_duration: float = 0.25
@export var hit_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var kill_color: Color = Color(1.0, 0.15, 0.15, 1.0)

@export var hitsound_enabled: bool = true
## Off: a killing shot plays the hitsound instead.
@export var killsound_enabled: bool = true
## Percent. 0 = silent.
@export_range(0, 100, 1) var hitsound_volume: int = 100
## Percent. 0 = silent.
@export_range(0, 100, 1) var killsound_volume: int = 100
## Copies of one sound that overlap. A further one cuts off the oldest.
@export_range(1, 16, 1) var max_voices: int = 8
## Null = silent.
@export var hitsound: AudioStream
## Null = silent.
@export var killsound: AudioStream
