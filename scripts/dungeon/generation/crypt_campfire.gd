class_name CryptCampfire
extends RefCounted
## Which room of a crypt level holds its campfire. One generation step, pure: it only reads the room graph.
## The room is an ordinary one (neither where the hero arrives nor where the stairs down are), as close as the
## level allows to the wanted number of rooms from the stairs up; DungeonGenerator keeps it from being a vault.


## The slot of the campfire's room. rooms_from_stairs: how far from the stairs up it should lie, in rooms.
## The nearest such room wins; ties are broken by rng.
static func slot_for(graph: RoomGraph, rooms_from_stairs: int, rng: RandomNumberGenerator) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for slot in graph.slots:
		if slot != graph.start_slot() and slot != graph.deepest_slot():
			candidates.append(slot)
	assert(not candidates.is_empty(), "a crypt level has rooms besides its stairs rooms")
	var nearest: int = candidates.map(
		func(slot: Vector2i) -> int: return absi(graph.depth_of(slot) - rooms_from_stairs)).min()
	candidates = candidates.filter(
		func(slot: Vector2i) -> bool: return absi(graph.depth_of(slot) - rooms_from_stairs) == nearest)
	return candidates[rng.randi_range(0, candidates.size() - 1)]
