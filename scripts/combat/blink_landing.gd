class_name BlinkLanding
extends RefCounted
## Where a blink ends. It flies in a straight line toward the spot aimed at and crosses whatever the hero can see
## across (floor, water, lava, boulders), but stops at a wall or a closed door. It lands on the farthest spot of
## that line, up to the one aimed at, where the hero's body fits on ground they can walk on: never in deep water,
## and never half inside a wall. With nowhere better it stays where it started.

## How finely the line is searched, in world units.
const STEP := 4.0
## The body is checked a little inside its edge, so a hero standing flush against a wall still fits.
const FIT_SHARE := 0.9
const BODY_EDGES: Array[Vector2] = [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]


## from, to: world positions. is_door_closed: cell -> bool (the map knows where doors are; the view knows which
## are shut).
static func find(
		from: Vector2, to: Vector2, map: DungeonMap, is_door_closed: Callable, body_radius: float) -> Vector2:
	var steps := ceili(from.distance_to(to) / STEP)
	var landing := from
	for step in range(1, steps + 1):
		var point := from.lerp(to, float(step) / steps)
		if not _crosses(_cell_of(point), map, is_door_closed):
			break
		if _fits(point, map, is_door_closed, body_radius * FIT_SHARE):
			landing = point
	return landing


static func _crosses(cell: Vector2i, map: DungeonMap, is_door_closed: Callable) -> bool:
	return map.is_see_through(cell) and not is_door_closed.call(cell)


static func _fits(point: Vector2, map: DungeonMap, is_door_closed: Callable, radius: float) -> bool:
	for edge in BODY_EDGES:
		var cell := _cell_of(point + edge * radius)
		if not map.is_walkable(cell) or is_door_closed.call(cell):
			return false
	return true


static func _cell_of(point: Vector2) -> Vector2i:
	return DungeonView.world_to_cell(point)
