class_name Item
extends RefCounted
## Something the player holds and finds as loot: a Weapon (attack button) or a Utility (the movement or the skill
## button, see Utility.Slot).
## Items are plain data. Subclasses add their own fields and expose the ones worth tuning through knobs().

## Stable identifier: used in tuning keys, so never rename one.
var id := ""
var display_name := ""
## One line shown when the item is found, so the player can compare it with what they hold.
var description := ""
var button_label := ""
var color := Color.WHITE


## The fields the Tune screen may change.
func knobs() -> Array[Knob]:
	return []


## How far the aim preview reaches: a full-strength drag aims this far.
func aim_range() -> float:
	return 0.0


## How far away a manual drag of the given strength (0..1) aims.
func aim_distance(strength: float) -> float:
	return clampf(strength, 0.0, 1.0) * aim_range()


## The strength (0..1) that aims this far away: the reverse of aim_distance(), for aiming at a spot (a mouse
## cursor) rather than with a drag. Beyond the item's reach it is full strength.
func strength_for_distance(distance: float) -> float:
	return clampf(distance / aim_range(), 0.0, 1.0) if aim_range() > 0.0 else 1.0


## What the button previews while aiming, or null when aiming doesn't matter.
func aim_shape() -> AimShape:
	return null
