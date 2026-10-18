class_name BossArena
extends RefCounted
## The boss arena of the crypt's last level, where the Lich waits: one generation step, pure. It picks the room (the
## one farthest from the stairs up, so never the start room, nor the campfire's, which CryptCampfire keeps off
## the farthest room; trap rooms keep clear of it too) and draws its floor plan: a hall with four 2x2 pillars
## that block shots, and the Lich's crypt, a recess in the middle of the hall's front (north) wall, where he stands.
## The arena is marked as a locking room (see LockingRoom): it locks when the hero walks in and opens when the Lich dies.
##
##   ###########.......###########      crypt (8 x 3)
##   ###########.......###########
##   ###########.......###########
##   ......................           hall (the room's full width)
##   ..##..................##..
##   ..##..................##..       pillars
##   ......................
##   ..##..................##..
##   ..##..................##..
##   ......................

## The Lich's crypt: a recess of this size at the middle of the front wall.
const CRYPT_SIZE := Vector2i(8, 3)
const PILLAR_COUNT := 4
const PILLAR_SIZE := 2
## The smallest room bounds the arena fits in.
const MIN_BOUNDS := Vector2i(16, 12)


## The slot of the arena: the room farthest from the start. Every other room can be reached without passing
## through it, so the lock never cuts the level in two.
static func slot_for(graph: RoomGraph) -> Vector2i:
	return graph.deepest_slot()


## The arena's floor plan inside the bounds a room may use: the hall below the Lich's crypt, minus the pillars.
static func room(bounds: Rect2i) -> Dictionary:
	assert(bounds.size.x >= MIN_BOUNDS.x and bounds.size.y >= MIN_BOUNDS.y, "the arena needs a bigger room")
	var cells := {}
	for y in range(hall(bounds).position.y, hall(bounds).end.y):
		for x in range(hall(bounds).position.x, hall(bounds).end.x):
			cells[Vector2i(x, y)] = true
	for y in range(crypt(bounds).position.y, crypt(bounds).end.y):
		for x in range(crypt(bounds).position.x, crypt(bounds).end.x):
			cells[Vector2i(x, y)] = true
	for cell in pillar_cells(bounds):
		cells.erase(cell)
	return cells


## The big open part of the room, under the Lich's crypt.
static func hall(bounds: Rect2i) -> Rect2i:
	return Rect2i(
		bounds.position + Vector2i(0, CRYPT_SIZE.y), bounds.size - Vector2i(0, CRYPT_SIZE.y))


## The Lich's crypt: a recess in the middle of the hall's front wall.
static func crypt(bounds: Rect2i) -> Rect2i:
	return Rect2i(
		Vector2i(bounds.position.x + (bounds.size.x - CRYPT_SIZE.x) / 2, bounds.position.y), CRYPT_SIZE)


## The cells of the four pillars: two by two blocks, a quarter of the way in from each side, above and below the middle.
static func pillar_cells(bounds: Rect2i) -> Array[Vector2i]:
	var area := hall(bounds)
	var left := area.position.x + area.size.x / 4 - PILLAR_SIZE / 2
	var right := area.end.x - area.size.x / 4 - PILLAR_SIZE / 2
	var middle := area.position.y + area.size.y / 2
	var above := middle - 4
	var below := middle + 3
	var cells: Array[Vector2i] = []
	for corner in [Vector2i(left, above), Vector2i(right, above), Vector2i(left, below), Vector2i(right, below)]:
		for dy in PILLAR_SIZE:
			for dx in PILLAR_SIZE:
				cells.append(corner + Vector2i(dx, dy))
	return cells


## Where the Lich stands: inside his crypt, facing the hall.
static func lich_cell(bounds: Rect2i) -> Vector2i:
	var recess := crypt(bounds)
	return recess.position + Vector2i(recess.size.x / 2, 1)


## The cell that carries the arena's locking mark: the middle of the hall, clear of the pillars.
static func mark_cell(bounds: Rect2i) -> Vector2i:
	var area := hall(bounds)
	return area.position + area.size / 2
