class_name SummonUndead
extends Weapon
## The Lich's Summon Undead, built as a Weapon like BoneSpray so the Enemy telegraphs it the same way: the wind-up is
## the cast, and what it releases is a SummonCast (the skeletons rise) rather than shots. It holds the spell's
## tunable numbers (Tune → Lich); the defaults live here. When to cast it, the summon cap and phase two are the
## SpellPicker's; where the skeletons rise is SummonSpots'; Summoning carries it out.
##
## How many rise per cast: skeletons_per_summon, but never more than the room left under the summon cap (the gap
## between the cap and the skeletons alive), so the cap is never passed.

const DEFAULT_RANGE_CELLS := 6.0
const DEFAULT_SKELETONS_PER_SUMMON := 3
const DEFAULT_WINDUP := 0.8
## How long a spot pulses before its skeleton stands up, in seconds.
const DEFAULT_RISE_SECONDS := 0.6
## How long after one spot starts to pulse the next one does, in seconds.
const DEFAULT_RISE_INTERVAL_SECONDS := 0.2

## How far from him (in cells) the skeletons may rise.
var summon_range_cells := DEFAULT_RANGE_CELLS
var skeletons_per_summon := DEFAULT_SKELETONS_PER_SUMMON
var rise_seconds := DEFAULT_RISE_SECONDS
var rise_interval_seconds := DEFAULT_RISE_INTERVAL_SECONDS


func _init() -> void:
	id = "summon_undead"
	display_name = "Summon Undead"
	description = "Raises skeletons from the floor."
	button_label = "SUMMON"
	color = Lich.COLOR
	windup = DEFAULT_WINDUP
	# One cast: the Lich's spell pause is his pace, not an ammo bar.
	ammo = 1
	reload = 0.0
	attack_interval = 0.0


func knobs() -> Array[Knob]:
	return [
		Knob.new("summon_range_cells", "Summon range (cells)", 2, 12, 0.5),
		Knob.new("skeletons_per_summon", "Skeletons per summon", 1, SpellPicker.MAX_SUMMON_CAP, 1),
		Knob.new("rise_seconds", "Spot pulses for (s)", 0.1, 3.0, 0.05),
		Knob.new("rise_interval_seconds", "Between spots (s)", 0.0, 1.0, 0.05),
		Knob.new("windup", "Telegraph (s)", 0.1, 2.0, 0.05),
	]


## How many skeletons the next cast raises, with living of them alive under a cap.
func count_to_raise(living: int, cap: int) -> int:
	return clampi(cap - living, 0, skeletons_per_summon)


## The wind-up releases the summons.
func attacks(_origin: Vector2, _direction: Vector2, _aim_distance: float) -> Array:
	return [SummonCast.new()]


## The preview is a ring of the summon range round him.
func aim_range() -> float:
	return summon_range_cells * DungeonView.TILE_SIZE


## Nothing to preview along an aim: the ring is drawn by Summoning.
func aim_shape() -> AimShape:
	return AimShape.line(0.0)
