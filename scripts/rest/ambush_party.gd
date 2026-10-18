class_name AmbushParty
extends RefCounted
## An ambush on its way: which monsters, where they will appear, and the seconds left until they arrive. The game
## ticks it while the hero is on the map and spawns the monsters when it is due. Leaving the map drops it (the
## lighting's roll stays spent in the map record, so nothing comes later). Pure.

## The Bestiary ids that come, one per cell.
var monster_ids: Array[String]
## Where each appears (as many as the map had room for; a monster with no cell does not come).
var cells: Array[Vector2i]
var seconds_left: float
## The campfire whose lighting brought them: the home they go back to if they give up.
var fire: Vector2i


func _init(ids: Array[String], at: Array[Vector2i], delay: float, from_fire: Vector2i) -> void:
	monster_ids = ids
	cells = at
	seconds_left = delay
	fire = from_fire


## Moves time on; true once, on the step they arrive.
func tick(delta: float) -> bool:
	if seconds_left <= 0.0:
		return false
	seconds_left -= delta
	return seconds_left <= 0.0
