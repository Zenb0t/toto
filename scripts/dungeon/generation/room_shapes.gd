class_name RoomShapes
extends RefCounted
## Room floor plans, as sets of cells ({Vector2i: true}) inside given bounds. Every shape is a union of
## overlapping rectangles, so it is always one connected piece. Pure: the caller passes the random generator.

enum Kind { RECT, L_SHAPE, CROSS, MERGED }

## Narrowest a room or one of its arms may be, in cells, so there is room to fight in it.
const MIN_THICKNESS := 7
## Pillars are 2x2 blocks this many cells clear of the room's edge, so doorways and walls stay walkable.
const PILLAR_SIZE := 2
const PILLAR_EDGE_CLEARANCE := 2
## Caves (see cave()): how thick the rock they start from is at least, how deep their walls wander in
## from it, how wide each stretch of wall stays put, and how much of each corner is rounded off.
const CAVE_MIN_THICKNESS := 11
const CAVE_MAX_BITE := 2
const CAVE_STRETCH := 3
const CAVE_CORNER := 3
## The middle of every side of a cave stays straight for this many cells each way, so a corridor can meet it.
const CAVE_MOUTH := 3


static func random_kind(rng: RandomNumberGenerator) -> Kind:
	return rng.randi_range(0, Kind.size() - 1) as Kind


static func build(kind: Kind, bounds: Rect2i, rng: RandomNumberGenerator) -> Dictionary:
	match kind:
		Kind.L_SHAPE:
			return _union(_l_shape(bounds, rng))
		Kind.CROSS:
			return _union(_cross(bounds, rng))
		Kind.MERGED:
			return _union(_merged(bounds, rng))
	return _union([rect(bounds, rng)])


## A natural cave, like Dungeon Crawl's Lair and Mines: a rough rectangle whose walls wander in and out in
## stretches of a few cells, with rounded corners. The middle of each side stays straight, so corridors can
## still meet it. Always one piece, and at least MIN_THICKNESS thick.
static func cave(bounds: Rect2i, rng: RandomNumberGenerator) -> Dictionary:
	var size := Vector2i(
		rng.randi_range(mini(CAVE_MIN_THICKNESS, bounds.size.x), bounds.size.x),
		rng.randi_range(mini(CAVE_MIN_THICKNESS, bounds.size.y), bounds.size.y))
	var area := Rect2i(bounds.position + (bounds.size - size) / 2, size)
	var top := _wandering_edge(size.x, rng)
	var bottom := _wandering_edge(size.x, rng)
	var left := _wandering_edge(size.y, rng)
	var right := _wandering_edge(size.y, rng)
	var cells := {}
	for y in size.y:
		for x in size.x:
			if y < top[x] or size.y - 1 - y < bottom[x] or x < left[y] or size.x - 1 - x < right[y]:
				continue
			var corner_x := mini(x, size.x - 1 - x)
			var corner_y := mini(y, size.y - 1 - y)
			if corner_x + corner_y < CAVE_CORNER:
				continue
			cells[area.position + Vector2i(x, y)] = true
	return cells


## How far a cave's wall bites in at each cell along a side: 0..CAVE_MAX_BITE, changing at most every
## CAVE_STRETCH cells and by one at a time, and 0 in the middle (the mouth).
static func _wandering_edge(length: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var bites := PackedInt32Array()
	bites.resize(length)
	var bite := rng.randi_range(0, CAVE_MAX_BITE)
	for i in length:
		if i % CAVE_STRETCH == 0:
			bite = clampi(bite + rng.randi_range(-1, 1), 0, CAVE_MAX_BITE)
		bites[i] = 0 if absi(i - length / 2) <= CAVE_MOUTH else bite
	return bites


## A rectangle at least MIN_THICKNESS on each side and at least half the bounds, centred give or take a cell.
static func rect(bounds: Rect2i, rng: RandomNumberGenerator) -> Rect2i:
	var size := Vector2i(
		rng.randi_range(maxi(MIN_THICKNESS, bounds.size.x / 2), bounds.size.x),
		rng.randi_range(maxi(MIN_THICKNESS, bounds.size.y / 2), bounds.size.y))
	var slack := bounds.size - size
	var offset := Vector2i(
		clampi(slack.x / 2 + rng.randi_range(-1, 1), 0, slack.x),
		clampi(slack.y / 2 + rng.randi_range(-1, 1), 0, slack.y))
	return Rect2i(bounds.position + offset, size)


## Adds up to count pillars at random spots, skipping any that would touch an edge or split the room.
## Returns the room without the pillar cells.
static func with_pillars(cells: Dictionary, count: int, rng: RandomNumberGenerator) -> Dictionary:
	var result := cells.duplicate()
	var spots := _pillar_spots(result)
	for _i in count:
		if spots.is_empty():
			break
		var corner: Vector2i = spots.pop_at(rng.randi_range(0, spots.size() - 1))
		var pillar := _block(corner)
		if not pillar.all(func(cell: Vector2i) -> bool: return result.has(cell)):
			continue
		var without := result.duplicate()
		for cell in pillar:
			without.erase(cell)
		if is_one_piece(without):
			result = without
	return result


## True when every cell can reach every other through side-by-side neighbours.
static func is_one_piece(cells: Dictionary) -> bool:
	if cells.is_empty():
		return true
	var start: Vector2i = cells.keys()[0]
	var reached := {start: true}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if cells.has(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return reached.size() == cells.size()


## Two arms meeting at one corner of the bounds.
static func _l_shape(bounds: Rect2i, rng: RandomNumberGenerator) -> Array[Rect2i]:
	var thickness := Vector2i(_thickness(bounds.size.x, rng), _thickness(bounds.size.y, rng))
	var at_right := rng.randi() % 2 == 0
	var at_bottom := rng.randi() % 2 == 0
	var arm_x := bounds.position.x + (bounds.size.x - thickness.x if at_right else 0)
	var arm_y := bounds.position.y + (bounds.size.y - thickness.y if at_bottom else 0)
	return [
		Rect2i(bounds.position.x, arm_y, bounds.size.x, thickness.y),
		Rect2i(arm_x, bounds.position.y, thickness.x, bounds.size.y),
	]


## A full-width bar and a full-height bar crossing near the middle.
static func _cross(bounds: Rect2i, rng: RandomNumberGenerator) -> Array[Rect2i]:
	var thickness := Vector2i(_thickness(bounds.size.x, rng), _thickness(bounds.size.y, rng))
	var middle := bounds.get_center()
	return [
		Rect2i(bounds.position.x, middle.y - thickness.y / 2, bounds.size.x, thickness.y),
		Rect2i(middle.x - thickness.x / 2, bounds.position.y, thickness.x, bounds.size.y),
	]


## Two rectangles from opposite corners, overlapping in the middle.
static func _merged(bounds: Rect2i, rng: RandomNumberGenerator) -> Array[Rect2i]:
	var size := Vector2i(
		rng.randi_range(maxi(MIN_THICKNESS, bounds.size.x * 3 / 5), bounds.size.x * 4 / 5),
		rng.randi_range(maxi(MIN_THICKNESS, bounds.size.y * 3 / 5), bounds.size.y * 4 / 5))
	var flip := rng.randi() % 2 == 0
	var first := Rect2i(bounds.position, size)
	var second := Rect2i(bounds.end - size, size)
	if flip:
		first.position.y = bounds.end.y - size.y
		second.position.y = bounds.position.y
	return [first, second]


static func _thickness(span: int, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(MIN_THICKNESS, maxi(MIN_THICKNESS, span / 2))


static func _union(parts: Array[Rect2i]) -> Dictionary:
	var cells := {}
	for part in parts:
		for y in range(part.position.y, part.end.y):
			for x in range(part.position.x, part.end.x):
				cells[Vector2i(x, y)] = true
	return cells


## Top-left corners where a pillar would sit well inside the room.
static func _pillar_spots(cells: Dictionary) -> Array[Vector2i]:
	var spots: Array[Vector2i] = []
	var reach := PILLAR_EDGE_CLEARANCE
	for corner: Vector2i in cells:
		var clear := true
		for y in range(corner.y - reach, corner.y + PILLAR_SIZE + reach):
			for x in range(corner.x - reach, corner.x + PILLAR_SIZE + reach):
				if not cells.has(Vector2i(x, y)):
					clear = false
		if clear:
			spots.append(corner)
	return spots


static func _block(corner: Vector2i) -> Array[Vector2i]:
	var block: Array[Vector2i] = []
	for y in PILLAR_SIZE:
		for x in PILLAR_SIZE:
			block.append(corner + Vector2i(x, y))
	return block
