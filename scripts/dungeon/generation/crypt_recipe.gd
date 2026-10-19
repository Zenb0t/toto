class_name CryptRecipe
extends RefCounted
## What the crypt's levels are made of, as plain data: where the campfire lies and how many bands start wandering.
## DungeonGenerator makes each level by it (the campfire; see CryptCampfire); the same recipe and seed always make
## the same level. The numbers are tunable (Tune → World, see knobs), and the defaults live here.

## How many levels the crypt has. The last one holds the boss arena (see BossArena) and has no stairs down.
const LEVELS := 3

## Stable identifier; also the prefix of its tuning keys.
var id := "crypt"
## The campfire lies in an ordinary room this many rooms from the stairs up (the nearest such room when the level
## has none that far). It never lies in the stairs-up room or the stairs-down room.
var campfire_rooms_from_stairs := 3
## The share of bands that start wandering a few cells about their room; the rest sleep. None starts awake.
var wandering_share := 0.15
## A trap room's band is picked as if its room lay this many levels deeper than it does (see TrapRoom): tougher, and
## with more monsters, than the level's usual bands.
var trap_band_extra_depth := 2


func knobs() -> Array[Knob]:
	return [
		Knob.new("campfire_rooms_from_stairs", "Crypt campfire, rooms from stairs", 1, 6, 1),
		Knob.new("wandering_share", "Crypt bands wandering (share)", 0.0, 1.0, 0.05),
		Knob.new("trap_band_extra_depth", "Crypt trap room band, levels deeper", 0, 6, 1),
	]
