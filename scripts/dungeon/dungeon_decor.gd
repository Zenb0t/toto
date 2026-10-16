class_name DungeonDecor
extends RefCounted
## How the dungeon dresses up, decided per cell from the map alone: the tint of each flagstone, where the
## cracks are, which walls stand as pillars, and where torches hang. Pure and deterministic: the same map
## always looks the same, without storing anything. Changes nothing about how the game plays.

## Every so many cells along a wall, at most one torch, and one banner between torches.
const TORCH_SPACING := 6
const BANNER_OFFSET := 3
## One floor cell along a wall in this many has something lying on it (a candle, a bottle, coins).
const CLUTTER_ONE_IN := 9
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


## Pillars and statues standing in a room are at most this many cells (the generator's are 2x2).
const PILLAR_MAX_CELLS := 4
const NEIGHBOURS_4: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## Walls standing free inside a room (pillars, statues): small blocks of wall with nothing but the room or
## each other around them, never the solid rock outside. Longer walls inside a room (a vault's chamber)
## stay walls.
static func pillar_cells(map: DungeonMap, wall_cells: Array[Vector2i]) -> Array[Vector2i]:
	var walls := {}
	for cell in wall_cells:
		walls[cell] = true
	var inside := {}
	for cell in wall_cells:
		if NEIGHBOURS_8.all(func(step: Vector2i) -> bool: return map.is_open(cell + step) or walls.has(cell + step)):
			inside[cell] = true
	var pillars: Array[Vector2i] = []
	var grouped := {}
	for start: Vector2i in inside:
		if grouped.has(start):
			continue
		var block := _connected(start, inside)
		for cell in block:
			grouped[cell] = true
		if block.size() <= PILLAR_MAX_CELLS and _stands_free(block, walls):
			pillars.append_array(block)
	return pillars


## The cells of a set connected to start (side by side).
static func _connected(start: Vector2i, cells: Dictionary) -> Array[Vector2i]:
	var block: Array[Vector2i] = [start]
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step in NEIGHBOURS_4:
			var next := cell + step
			if cells.has(next) and next not in block:
				block.append(next)
				frontier.append(next)
	return block


## Whether a block of wall stands free: no wall next to it (corners included) that isn't part of it.
static func _stands_free(block: Array[Vector2i], walls: Dictionary) -> bool:
	for cell in block:
		for step in NEIGHBOURS_8:
			var next := cell + step
			if walls.has(next) and next not in block:
				return false
	return true


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


## Walls with a banner: like torches, on walls facing the camera, halfway between the torches, and only
## some of those spots.
static func banner_cells(map: DungeonMap, wall_cells: Array[Vector2i]) -> Array[Vector2i]:
	var pillars := pillar_cells(map, wall_cells)
	var banners: Array[Vector2i] = []
	for cell in wall_cells:
		var below := cell + Vector2i.DOWN
		if not map.is_open(below) or map.is_door(below) or cell in pillars:
			continue
		if posmod(cell.x, TORCH_SPACING) == posmod(cell.y * 3 + BANNER_OFFSET, TORCH_SPACING) and noise(cell, 7) < 0.5:
			banners.append(cell)
	return banners


## Floor cells along a wall (the wall above them) with something small lying on them, and which thing (an
## index into the caller's list of kinds). Never on doorways, the stairs or where loot or monsters start.
static func clutter_cells(map: DungeonMap, kinds: int) -> Dictionary:
	var clutter := {}
	var busy := {map.exit_cell: true, map.player_spawn: true}
	for cell in map.loot_cells + map.enemy_spawns:
		busy[cell] = true
	for cell in map.open_cells():
		if busy.has(cell) or not map.is_standable(cell) or map.is_door(cell):
			continue
		if map.is_open(cell + Vector2i.UP) or not map.is_clear_of_doors(cell):
			continue
		if noise(cell, 8) * CLUTTER_ONE_IN < 1.0:
			clutter[cell] = floori(noise(cell, 9) * kinds) % kinds
	return clutter


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
