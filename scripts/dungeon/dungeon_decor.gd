class_name DungeonDecor
extends RefCounted
## How the dungeon dresses up, decided per cell from the map alone: the tint of each flagstone, where the
## cracks are, which walls stand as pillars, and where torches hang. Pure and deterministic: the same map
## always looks the same, without storing anything. Changes nothing about how the game plays.

## Every so many cells along a wall, at most one torch.
const TORCH_SPACING := 6
## One floor tile in this many is cracked.
const CRACK_ONE_IN := 14
## How far a torch's light reaches across the floor, in cells.
const TORCH_REACH := 3.5
const NEIGHBOURS_8: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


## A number from 0 to 1 that looks random but is always the same for a cell (and salt).
static func noise(cell: Vector2i, salt := 0) -> float:
	return float(hash(Vector3i(cell.x, cell.y, salt)) % 10007) / 10006.0


## How much lighter (above 0) or darker (below 0) a cell's stone is than the plain colour, -1..1.
static func tint(cell: Vector2i) -> float:
	return noise(cell, 1) * 2.0 - 1.0


## A crack across a floor tile, as points within the tile (0..1 on each side), or no points for most tiles.
static func crack(cell: Vector2i) -> PackedVector2Array:
	if noise(cell, 2) * CRACK_ONE_IN >= 1.0:
		return PackedVector2Array()
	var start := Vector2(0.15 + noise(cell, 3) * 0.3, 0.1)
	var bend := Vector2(0.3 + noise(cell, 4) * 0.4, 0.45 + noise(cell, 5) * 0.2)
	var end := Vector2(0.55 + noise(cell, 6) * 0.35, 0.9)
	return PackedVector2Array([start, bend, end])


## Walls standing inside a room (pillars, statues): every cell around them is part of the room or of
## another wall around it, never the solid rock outside.
static func pillar_cells(map: DungeonMap, wall_cells: Array[Vector2i]) -> Array[Vector2i]:
	var walls := {}
	for cell in wall_cells:
		walls[cell] = true
	var pillars: Array[Vector2i] = []
	for cell in wall_cells:
		var inside := true
		for step in NEIGHBOURS_8:
			if not map.is_open(cell + step) and not walls.has(cell + step):
				inside = false
				break
		if inside:
			pillars.append(cell)
	return pillars


## Walls with a torch: they face the camera (open floor right below them, not a door), they aren't
## pillars, and torches are spread out along the walls.
static func torch_cells(map: DungeonMap, wall_cells: Array[Vector2i]) -> Array[Vector2i]:
	var pillars := pillar_cells(map, wall_cells)
	var torches: Array[Vector2i] = []
	for cell in wall_cells:
		var below := cell + Vector2i.DOWN
		if not map.is_open(below) or map.is_door(below) or cell in pillars:
			continue
		if posmod(cell.x, TORCH_SPACING) == posmod(cell.y * 3, TORCH_SPACING):
			torches.append(cell)
	return torches


## How warmly torchlight falls on each open cell: 1 right below a torch, fading to 0 at TORCH_REACH.
## Only open cells get light, so it never spills over walls (cell -> 0..1, only for lit cells).
static func torch_light(map: DungeonMap, torches: Array[Vector2i]) -> Dictionary:
	var light := {}
	var reach := ceili(TORCH_REACH)
	for torch in torches:
		var source := Vector2(torch) + Vector2(0.5, 1.0)
		for dy in range(0, reach + 1):
			for dx in range(-reach, reach + 1):
				var cell := torch + Vector2i(dx, dy)
				if not map.is_open(cell):
					continue
				var warmth := 1.0 - source.distance_to(Vector2(cell) + Vector2(0.5, 0.5)) / TORCH_REACH
				if warmth > light.get(cell, 0.0):
					light[cell] = warmth
	return light
