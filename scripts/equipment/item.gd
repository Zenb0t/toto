class_name Item
extends RefCounted
## Something the player holds and finds as loot: a Weapon (attack button) or a Utility (second button).
## Items are plain data. Subclasses add their own fields and expose the ones worth tuning through knobs().

## Stable identifier: used in tuning keys, so never rename one.
var id := ""
var display_name := ""
## One line shown when the item is found, so the player can compare it with what they hold.
var description := ""
var button_label := ""
var color := Color.WHITE
## Seconds between uses.
var cooldown := 0.8


## The fields the Tune screen may change.
func knobs() -> Array[Knob]:
	return []


## How far the aim preview reaches.
func aim_range() -> float:
	return 0.0


## What the button previews while aiming, or null when aiming doesn't matter.
func aim_shape() -> AimShape:
	return null
