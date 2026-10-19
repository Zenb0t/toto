class_name BossArena
extends RefCounted
## The boss arena of the crypt's last level, where the Lich waits: one generation step, pure. It picks the room (the
## one farthest from the stairs up, so never the start room, nor the campfire's, which CryptCampfire keeps off
## the farthest room; trap rooms keep clear of it too) and draws its floor plan: a hall with four 2x2 pillars
## that block shots, and the Lich's crypt, a recess in the middle of the hall's front (north) wall, where he stands.
## The back row of the crypt reaches a nook further to each side, which no doorway of the hall can see into: it is
## where he hides when hurt before the arena locks (see Hideout).
## The crypt faces north unless a corridor reaches the room from the north, which would open a door into the back of
## the crypt: then the whole plan is mirrored and it faces south (see faces_south). Corridors open only where no
## doorway sees into the nooks (see admits_door). The functions below describe the
## north-facing plan; room, lich_cell and mark_cell take `south` to mirror their answer.
## The arena is marked as a locking room (see LockingRoom): it locks when the hero walks in and opens when the Lich dies.
##
##   #####............#####      back row of the crypt: a nook on each side (2 cells)
##   #######........#######      crypt (8 x 3)
##   #######........#######
##   ......................           hall (the room's full width)
##   ..##..................##..
##   ..##..................##..       pillars
##   ......................
##   ..##..................##..
##   ..##..................##..
##   ......................

## The Lich's crypt: a recess of this size at the middle of the front wall.
const CRYPT_SIZE := Vector2i(8, 3)
## The back row of the crypt is this many cells wider on each side: the nooks a doorway can't see.
const NOOK_WIDTH := 2
const PILLAR_COUNT := 4
const PILLAR_SIZE := 2
## The smallest room bounds the arena fits in.
const MIN_BOUNDS := Vector2i(16, 12)


## The slot of the arena: the room farthest from the start. Every other room can be reached without passing
## through it, so the lock never cuts the level in two.
static func slot_for(graph: RoomGraph) -> Vector2i:
	return graph.deepest_slot()


## The arena's floor plan inside the bounds a room may use: the hall below the Lich's crypt, minus the pillars.
static func room(bounds: Rect2i, south := false) -> Dictionary:
	assert(bounds.size.x >= MIN_BOUNDS.x and bounds.size.y >= MIN_BOUNDS.y, "the arena needs a bigger room")
	var cells := {}
	for y in range(hall(bounds).position.y, hall(bounds).end.y):
		for x in range(hall(bounds).position.x, hall(bounds).end.x):
			cells[Vector2i(x, y)] = true
	for y in range(crypt(bounds).position.y, crypt(bounds).end.y):
		for x in range(crypt(bounds).position.x, crypt(bounds).end.x):
			cells[Vector2i(x, y)] = true
	for cell in nook_cells(bounds):
		cells[cell] = true
	for cell in pillar_cells(bounds):
		cells.erase(cell)
	if not south:
		return cells
	var mirrored := {}
	for cell: Vector2i in cells:
		mirrored[oriented(cell, bounds, true)] = true
	return mirrored


## The two nooks at the ends of the crypt's back row.
static func nook_cells(bounds: Rect2i) -> Array[Vector2i]:
	var recess := crypt(bounds)
	var cells: Array[Vector2i] = []
	for step in NOOK_WIDTH:
		cells.append(Vector2i(recess.position.x - 1 - step, recess.position.y))
		cells.append(Vector2i(recess.end.x + step, recess.position.y))
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
static func lich_cell(bounds: Rect2i, south := false) -> Vector2i:
	var recess := crypt(bounds)
	return oriented(recess.position + Vector2i(recess.size.x / 2, 1), bounds, south)


## The cell that carries the arena's locking mark: the middle of the hall, clear of the pillars.
static func mark_cell(bounds: Rect2i, south := false) -> Vector2i:
	var area := hall(bounds)
	return oriented(area.position + area.size / 2, bounds, south)


## Whether a corridor may open into the arena next to this cell of it (the cell just inside the door; `sideways`
## for a corridor from the room beside it): never into the crypt or its nooks, and through a side wall only in the
## half of the hall away from the crypt. A doorway higher up the side wall looks across the crypt's mouth into the
## far nook, and one into the crypt sees both: the Lich would have nowhere to hide (see Hideout).
static func admits_door(cell: Vector2i, sideways: bool, bounds: Rect2i, south := false) -> bool:
	var plan_cell := oriented(cell, bounds, south)
	if crypt(bounds).has_point(plan_cell) or plan_cell in nook_cells(bounds):
		return false
	var area := hall(bounds)
	return not sideways or plan_cell.y >= area.position.y + area.size.y / 2


## Whether the arena in this slot is drawn with its crypt on the south side: when it is linked to the room above
## it and not to the one below. (Linked on both sides, it stays north-facing and the corridor from the north comes
## down beside the crypt, see admits_door.)
static func faces_south(graph: RoomGraph, slot: Vector2i) -> bool:
	return graph.is_linked(slot, slot + Vector2i.UP) and not graph.is_linked(slot, slot + Vector2i.DOWN)


## A cell of the north-facing plan, where it lies when the plan is mirrored top to bottom (south) or not.
static func oriented(cell: Vector2i, bounds: Rect2i, south: bool) -> Vector2i:
	if not south:
		return cell
	return Vector2i(cell.x, bounds.position.y * 2 + bounds.size.y - 1 - cell.y)
