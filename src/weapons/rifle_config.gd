class_name RifleConfig
extends Resource
## Feel values of one rifle. Rifle1 and Rifle2 (#26) are instances of this.

## Shots per second while fire is held (or the fastest tap rate). Capped at the tick rate.
@export_range(1.0, 20.0, 0.5, "or_greater") var shots_per_second: float = 4.0
## Off: tap only, holding fires once.
@export var full_auto: bool = true
## Damage per second of continuous fire. Damage per shot = dps / shots_per_second.
@export var dps: float = 100.0
