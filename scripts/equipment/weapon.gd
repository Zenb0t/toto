class_name Weapon
extends RefCounted
## What the attack button does. A plain data object: the player decides when to attack,
## the weapon decides what the attack is.
## The defaults describe the starter Wand, which fires a single magic bolt.

var display_name := "Wand"
var button_label := "WAND"
var color := Color(1, 0.8, 0.3)
## Seconds between attacks.
var cooldown := 0.8
## Seconds between releasing the button and the shot leaving, so attacks feel deliberate.
var windup := 0.3
var shot_speed := 300.0
var shot_damage := 1
var shot_range := 420.0


## How far the aim preview reaches.
func aim_range() -> float:
	return shot_range


func shots(origin: Vector2, direction: Vector2) -> Array[Shot]:
	return [Shot.new(origin, direction, shot_speed, shot_damage, shot_range)]
