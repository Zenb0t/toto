class_name Pathfinder
extends RefCounted
## Grid navigation over a DungeonMap, for enemies: the way around walls and pillars, and whether one point
## can see another. Doors count as walkable; a locked room keeps its enemies in with the player anyway.

## How finely a sight line is checked against the grid, in pixels.
const SIGHT_STEP := 8.0

var _map: DungeonMap
var _grid := AStarGrid2D.new()


func _init(map: DungeonMap) -> void:
	_map = map
	_grid.region = Rect2i(Vector2i.ZERO, map.size)
	_grid.cell_size = Vector2.ONE * DungeonView.TILE_SIZE
	_grid.offset = _grid.cell_size / 2.0
	# Diagonal steps only where both side cells are open, so paths never clip a wall's corner.
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for y in map.size.y:
		for x in map.size.x:
			_grid.set_point_solid(Vector2i(x, y), not map.is_walkable(Vector2i(x, y)))


## World positions of cell centres from (excluding) the start cell to the goal cell; empty if there is no way.
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := DungeonView.world_to_cell(from)
	var goal := DungeonView.world_to_cell(to)
	if not _is_open(start) or not _is_open(goal):
		return PackedVector2Array()
	var points := _grid.get_point_path(start, goal)
	return points.slice(1) if points.size() > 1 else points


## True when nothing but walkable floor lies on the straight line between the two points.
func can_see(from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to) / SIGHT_STEP)
	for i in range(1, steps):
		if not _map.is_walkable(DungeonView.world_to_cell(from.lerp(to, float(i) / steps))):
			return false
	return true


func _is_open(cell: Vector2i) -> bool:
	return _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell)
