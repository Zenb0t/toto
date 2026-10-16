class_name RoomGraph
extends RefCounted
## Which rooms a generated dungeon has and how they connect, before any shapes are drawn.
## Rooms sit on a coarse grid of slots; links only join neighbouring slots, so corridors stay short
## and never cross. Pure: the caller passes the random number generator.

const NEIGHBOURS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

## Slots that hold a room, in the order they were added. The first one is the start room.
var slots: Array[Vector2i] = []
## Each link joins two neighbouring slots, stored as [a, b].
var links: Array = []
var _depth_by_slot := {}  # Vector2i -> int, rooms between this one and the start


## Grows a tree of room_count rooms from a random slot (each new room joins a random neighbour of the
## rooms so far), then adds up to extra_links more links between neighbouring rooms, so the map has loops
## instead of only dead ends.
static func grow(
		grid_size: Vector2i, room_count: int, extra_links: int, rng: RandomNumberGenerator) -> RoomGraph:
	assert(room_count <= grid_size.x * grid_size.y, "more rooms than slots")
	var graph := RoomGraph.new()
	graph.slots.append(Vector2i(rng.randi_range(0, grid_size.x - 1), rng.randi_range(0, grid_size.y - 1)))
	while graph.slots.size() < room_count:
		var frontier := graph._open_neighbours(grid_size)
		var pick: Array = frontier[rng.randi_range(0, frontier.size() - 1)]
		graph.slots.append(pick[1])
		graph.links.append(pick)
	var spare := graph._unlinked_neighbours()
	for _i in mini(extra_links, spare.size()):
		graph.links.append(spare.pop_at(rng.randi_range(0, spare.size() - 1)))
	graph._measure_depths()
	return graph


func start_slot() -> Vector2i:
	return slots[0]


## How many links away from the start room a room is.
func depth_of(slot: Vector2i) -> int:
	return _depth_by_slot[slot]


## The room farthest from the start (the first one found, if several tie).
func deepest_slot() -> Vector2i:
	var deepest := slots[0]
	for slot in slots:
		if depth_of(slot) > depth_of(deepest):
			deepest = slot
	return deepest


## How many links lead in and out of a room: 1 means a dead end.
func link_count(slot: Vector2i) -> int:
	return links.filter(func(link: Array) -> bool: return slot in link).size()


func is_linked(a: Vector2i, b: Vector2i) -> bool:
	return links.any(func(link: Array) -> bool: return (link[0] == a and link[1] == b) or (link[0] == b and link[1] == a))


## Pairs [room slot, free neighbour slot] the tree can grow into.
func _open_neighbours(grid_size: Vector2i) -> Array:
	var open := []
	for slot in slots:
		for step in NEIGHBOURS:
			var next := slot + step
			if _inside(next, grid_size) and next not in slots:
				open.append([slot, next])
	return open


func _unlinked_neighbours() -> Array:
	var pairs := []
	for slot in slots:
		for step in [Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = slot + step
			if next in slots and not is_linked(slot, next):
				pairs.append([slot, next])
	return pairs


func _measure_depths() -> void:
	_depth_by_slot = {slots[0]: 0}
	var frontier: Array[Vector2i] = [slots[0]]
	while not frontier.is_empty():
		var slot: Vector2i = frontier.pop_front()
		for link: Array in links:
			var other: Vector2i = link[1] if link[0] == slot else (link[0] if link[1] == slot else slot)
			if other != slot and not _depth_by_slot.has(other):
				_depth_by_slot[other] = _depth_by_slot[slot] + 1
				frontier.append(other)


static func _inside(slot: Vector2i, grid_size: Vector2i) -> bool:
	return slot.x >= 0 and slot.y >= 0 and slot.x < grid_size.x and slot.y < grid_size.y
