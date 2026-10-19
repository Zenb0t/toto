class_name TrapRoom
extends RefCounted
## The crypt's trap rooms: one generation step, pure. A trap room looks like any other room with a chest in the
## middle. Walking in seals it (it is marked as a locking room, see LockingRoom), and a band tougher than the level's
## usual wakes and fights to the death; the chest opens only once the band is dead. The last level has none (its
## farthest room is the boss arena); the first two have one each.


## Whether a crypt level holds a trap room.
static func on_level(floor_number: int) -> bool:
	return floor_number < CryptRecipe.LEVELS


## The slot of the trap room: an ordinary room, so never the start room, the stairs-down room (the boss arena on the
## last level), nor any of the slots in `taken` (the campfire's room). The caller keeps it from being a vault. Ties
## are broken by rng. NO_SLOT when the level has no such room.
static func slot_for(graph: RoomGraph, taken: Array[Vector2i], rng: RandomNumberGenerator) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for slot in graph.slots:
		if slot != graph.start_slot() and slot != graph.deepest_slot() and slot not in taken:
			candidates.append(slot)
	if candidates.is_empty():
		return DungeonGenerator.NO_SLOT
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## The depth the band's monsters are picked for: the room's danger, `extra_depth` levels deeper.
static func band_depth(danger: int, extra_depth: int) -> int:
	return danger + extra_depth
