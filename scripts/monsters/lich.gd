class_name Lich
extends RefCounted
## The Lich: the unique boss at the bottom of the crypt, killed to win a run. A named monster of his own, not the
## regular Necromancer. He casts Mephitic Clouds (his other spells are in SpellPicker) from a distance: he keeps
## his distance and backs off as the hero closes in. He lives in the boss arena (see BossArena) and never gives up
## a chase. This holds his tunable numbers (Tune → Lich); the defaults live here, and Bestiary lists the monster
## they make.

const ID := "lich"
## His symbol in the map format (see DungeonMapParser).
const LETTER := "l"
const DEFAULT_MAX_HEALTH := 3000
const DEFAULT_SPEED_MULTIPLIER := 1.0
const DEFAULT_SIZE := 1.3
## How far from the hero he likes to stay; closer than three quarters of it, he backs off.
const DEFAULT_KEEP_DISTANCE_CELLS := 8.0
## Dark purple: the colour of his robe, and of the burst when he dies.
const COLOR := Color(0.42, 0.2, 0.62)

## Stable identifier; also the prefix of his tuning keys.
var id := ID
var max_health := DEFAULT_MAX_HEALTH
## How fast he moves, relative to the tuned enemy speed.
var speed_multiplier := DEFAULT_SPEED_MULTIPLIER
## How big he is, relative to an ordinary enemy: his body (what attacks hit) and his model.
var size := DEFAULT_SIZE
var keep_distance_cells := DEFAULT_KEEP_DISTANCE_CELLS


func knobs() -> Array[Knob]:
	return [
		Knob.new("max_health", "Health (next visit)", 500, 20000, 100),
		Knob.new("speed_multiplier", "Speed (x enemy speed)", 0.3, 2.0, 0.05),
		Knob.new("size", "Size (x, next visit)", 1.0, 2.0, 0.05),
		Knob.new("keep_distance_cells", "Keeps his distance (cells)", 3, 14, 0.5),
	]


## The Bestiary entry these numbers make.
func monster() -> Monster:
	return Monster.new(ID, "Lich", LETTER, "mephitic_cloud", max_health, speed_multiplier, size, 0, "undead", COLOR)
