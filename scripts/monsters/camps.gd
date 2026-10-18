class_name Camps
extends RefCounted
## Which monsters live at a campfire. A camp is a band whose home is the campfire it stands round (see
## SetPieces.camp); a campfire with no monster near it is a lone one. The map only knows its campfires and its
## monsters, so a monster belongs to the campfire close by. Pure.

## How far, in cells (either way), a camp's monsters stand from their campfire.
const RADIUS_CELLS := 3
## Band ids of camps start here, clear of room numbers, which count up from 0.
const FIRST_BAND_ID := 1_000_000


## The campfire a monster spawning at this cell lives at, or DungeonMap.NO_CELL when it lives at no camp.
static func campfire_of(map: DungeonMap, spawn_cell: Vector2i) -> Vector2i:
	for fire in map.campfire_cells:
		var apart := (spawn_cell - fire).abs()
		if maxi(apart.x, apart.y) <= RADIUS_CELLS:
			return fire
	return DungeonMap.NO_CELL


## The campfires that are a band's home, i.e. that have monsters standing round them.
static func camp_campfires(map: DungeonMap) -> Array[Vector2i]:
	var fires: Array[Vector2i] = []
	for cell in map.enemy_spawns:
		var fire := campfire_of(map, cell)
		if fire != DungeonMap.NO_CELL and fire not in fires:
			fires.append(fire)
	return fires


## The campfires nobody lives at.
static func lone_campfires(map: DungeonMap) -> Array[Vector2i]:
	var lone: Array[Vector2i] = []
	var camps := camp_campfires(map)
	for fire in map.campfire_cells:
		if fire not in camps:
			lone.append(fire)
	return lone


## Whether a camp's band still holds its campfire: any monster of the camp is alive (not killed in the record).
## A campfire nobody lives at is never held.
static func is_held(map: DungeonMap, campfire: Vector2i, record: MapRecord) -> bool:
	for cell in map.enemy_spawns:
		if campfire_of(map, cell) == campfire and not record.is_killed(cell):
			return true
	return false


## The id of the band living at a campfire (see Band.start_of): different for each campfire of a map.
static func band_id(map: DungeonMap, campfire: Vector2i) -> int:
	return FIRST_BAND_ID + campfire.y * map.size.x + campfire.x
