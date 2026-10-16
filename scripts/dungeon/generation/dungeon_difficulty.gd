class_name DungeonDifficulty
extends RefCounted
## How tough a room is, by how far it is from the start (its depth, in rooms). Pure.
## Near the start: a couple of swords and wands. Deeper: more enemies, crossbows, then fireballs.

const MAX_ENEMIES := 6
## Like Dungeon Crawl's out-of-depth monsters: now and then a room holds enemies from deeper in. Rooms are
## optional, so reading the danger and walking away is a choice.
const OUT_OF_DEPTH_CHANCE := 0.15
const OUT_OF_DEPTH_EXTRA := 2
## Enemy map letters (see DungeonMapParser) that may appear at each depth; the last entry covers anything deeper.
const POOLS_BY_DEPTH := [
	["s", "s", "w"],
	["s", "w", "w", "c"],
	["s", "w", "c", "c", "f"],
	["s", "w", "c", "f", "f"],
]


## The depth a room's enemies are picked for: usually its own, sometimes deeper.
static func rolled_depth(depth: int, rng: RandomNumberGenerator) -> int:
	return depth + OUT_OF_DEPTH_EXTRA if rng.randf() < OUT_OF_DEPTH_CHANCE else depth


static func enemy_count(depth: int) -> int:
	return clampi(depth + 1, 2, MAX_ENEMIES)


## The map letters of the enemies in a room at this depth (at least 1).
static func enemy_letters(depth: int, rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array = POOLS_BY_DEPTH[clampi(depth - 1, 0, POOLS_BY_DEPTH.size() - 1)]
	var letters: Array[String] = []
	for _i in enemy_count(depth):
		letters.append(pool[rng.randi_range(0, pool.size() - 1)])
	return letters
