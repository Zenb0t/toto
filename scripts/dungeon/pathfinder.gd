class_name Pathfinder
extends RefCounted
## Grid navigation over a DungeonMap, for enemies: the way around walls, pillars and water (lava only when
## there is no other way), and whether one point can see another (across water and lava, not through walls).
## Doors count as walkable; a locked room keeps its enemies in with the player anyway.

## How finely a sight line is checked against the grid, in pixels.
const SIGHT_STEP := 8.0
## A lava cell costs this many floor cells, so paths go round it when they can.
const LAVA_COST := 10.0
## Wading is slow: a shallow water cell costs this many floor cells.
const SHALLOW_COST := 2.0

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
			var cell := Vector2i(x, y)
			_grid.set_point_solid(cell, not map.is_walkable(cell))
			if map.terrain_at(cell) == DungeonMap.Terrain.LAVA:
				_grid.set_point_weight_scale(cell, LAVA_COST)
			elif map.terrain_at(cell) == DungeonMap.Terrain.SHALLOW:
				_grid.set_point_weight_scale(cell, SHALLOW_COST)


## World positions of cell centres from (excluding) the start cell to the goal cell; empty if there is no way.
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := DungeonView.world_to_cell(from)
	var goal := DungeonView.world_to_cell(to)
	if not _is_open(start) or not _is_open(goal):
		return PackedVector2Array()
	var points := _grid.get_point_path(start, goal)
	return points.slice(1) if points.size() > 1 else points


## True when no wall lies on the straight line between the two points.
func can_see(from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to) / SIGHT_STEP)
	for i in range(1, steps):
		if not _map.is_see_through(DungeonView.world_to_cell(from.lerp(to, float(i) / steps))):
			return false
	return true


## True on ground one can walk onto and stand on without harm (not a wall, deep water or lava).
func is_safe_footing(point: Vector2) -> bool:
	var cell := DungeonView.world_to_cell(point)
	return _is_open(cell) and _map.terrain_at(cell) != DungeonMap.Terrain.LAVA


func _is_open(cell: Vector2i) -> bool:
	return _grid.is_in_boundsv(cell) and not _grid.is_point_solid(cell)
