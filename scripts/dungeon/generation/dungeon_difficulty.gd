class_name DungeonDifficulty
extends RefCounted
## How tough a room is, by its depth: how far it is from the start, in rooms. Pure.
## Like Dungeon Crawl, the monsters change with depth: kobolds and goblins near the start, then humans,
## orcs and orc wizards, sturdy dwarves, and finally ogres. Deeper rooms also hold more of them.

const MAX_ENEMIES := 6
## Like Dungeon Crawl's out-of-depth monsters: now and then a room holds enemies from deeper in. Rooms are
## optional, so reading the danger and walking away is a choice.
const OUT_OF_DEPTH_CHANCE := 0.15
const OUT_OF_DEPTH_EXTRA := 2
## Monster letters (see Bestiary) that may appear at each danger level (see danger()); a letter listed twice is twice as likely.
## The last entry covers anything deeper.
const POOLS_BY_DEPTH := [
	["k", "k", "g", "s"],
	["k", "g", "a", "s", "w"],
	["g", "a", "s", "w", "c", "o"],
	["s", "c", "a", "o", "o", "f", "n"],
	["o", "c", "f", "W", "d", "n"],
	["o", "W", "d", "d", "e", "n"],
	["o", "W", "d", "O", "e"],
	["W", "d", "O", "O", "e", "o"],
]


## How dangerous a room is: one level per floor down, plus half a level per room away from the start, so
## rooms on one floor differ less than floors do (Dungeon Crawl's monsters, too, follow the floor's depth).
static func danger(room_depth: int, floor_number: int) -> int:
	return (floor_number - 1) + ceili(room_depth / 2.0)


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
