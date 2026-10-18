class_name RestProfile
extends RefCounted
## How a place of rest heals: how long the rest lasts, how far its light reaches, how much it heals and how fast,
## and how long it is spent afterwards. A campfire is the first profile (campfire()); the inn's will be another set
## of the same numbers (a short rest, a full heal, no wait after) and an ambush roll another field, so the rules
## that carry a rest out (Campfire, MonstersAround) never name a particular place. Pure; every number is a Knob.

## Tune keys are "<id>.<field>".
var id := "campfire"
## The most a rest heals the hero up to, as a share of their maximum health (resting never heals past it).
var heal_share := 0.5
## Health points healed per second while the hero stands in the light.
var heal_per_second := 50.0
## How long the fire burns once lit, in seconds.
var burn_seconds := 10.0
## How long a burnt-out fire lies in embers before it can be lit again, in seconds of play on its map.
var embers_seconds := 90.0
## How far from the fire its light (and so the healing) reaches, in cells.
var light_radius_cells := 2.5
## How close the hero must stand to light it, in cells.
var reach_cells := 2.0


## The campfire's numbers (the defaults of this class).
static func campfire() -> RestProfile:
	return RestProfile.new()


## The fields the Tune screen may change.
func knobs() -> Array[Knob]:
	return [
		Knob.new("heal_share", "Heals up to (share of max health)", 0.1, 1.0, 0.05),
		Knob.new("heal_per_second", "Heal rate (HP/s)", 5, 300, 5),
		Knob.new("burn_seconds", "Burns for (s)", 3, 60, 1),
		Knob.new("embers_seconds", "Embers until relit (s)", 0, 300, 5),
		Knob.new("light_radius_cells", "Light reaches (cells)", 1, 6, 0.25),
		Knob.new("reach_cells", "Rest from (cells)", 1, 4, 0.25),
	]


## The health a rest heals up to for a hero with this maximum.
func heal_ceiling(max_health: int) -> int:
	return floori(max_health * heal_share)


## Whether a spot this many cells from the fire is in its light.
func lights(cells_from_fire: float) -> bool:
	return cells_from_fire <= light_radius_cells


## Whether the hero, this many cells from the fire, is close enough to light it.
func is_within_reach(cells_from_fire: float) -> bool:
	return cells_from_fire <= reach_cells
