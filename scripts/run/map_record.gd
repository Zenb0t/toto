class_name MapRecord
extends RefCounted
## What the hero changed on one map, so the map can be thrown away on leaving and made again from its seed on
## return, the way it was left: monsters killed, chests opened, floor items taken, items dropped, cells explored
## and monsters left hurt, the state of its campfires, how many times each has been lit (the ambush rolls spent) and
## whether the Lich is dead. Things are known by where the map puts them (an enemy by its spawn cell, a floor item by its
## loot cell, a chest by the id of what holds it: a room, or a set piece like the ruin, see Ruins.NUMBER), which is what
## lets a record match its regenerated map.
## Pure; to_dict / from_dict give a plain dictionary for saving a run later.

## Something lying on the floor that the map didn't start with (a swapped-out weapon, a chest's find, a drop).
class DroppedItem:
	extends RefCounted
	var item_id: String
	## A potion rather than gear (a weapon or a utility).
	var is_potion: bool
	var position: Vector2

	func _init(dropped_id: String, potion: bool, at: Vector2) -> void:
		item_id = dropped_id
		is_potion = potion
		position = at


## The version of the generator that made the map (see MapSpec.generator_version).
var generator_version: int
var _killed := {}  # Vector2i (spawn cell) -> true
var _opened_chests := {}  # int (chest id) -> true
var _taken_loot := {}  # Vector2i (loot cell) -> true
var _explored: Array[Vector2i] = []
var _dropped: Array[DroppedItem] = []
var _hurt := {}  # Vector2i (spawn cell) -> {"health": int, "left_at": float}
var _lich_dead := false
var _campfires := {}  # Vector2i (campfire cell) -> {"state": Campfire.State, "seconds_left": float}
var _lightings := {}  # Vector2i (campfire cell) -> int: how many times it has been lit (each made its ambush roll)


func _init(made_by_version: int) -> void:
	generator_version = made_by_version


func kill(enemy_id: Vector2i) -> void:
	_killed[enemy_id] = true
	_hurt.erase(enemy_id)


func is_killed(enemy_id: Vector2i) -> bool:
	return _killed.has(enemy_id)


## The Lich died on this map (his spawn cell is also among the killed).
func kill_lich() -> void:
	_lich_dead = true


func is_lich_dead() -> bool:
	return _lich_dead


func open_chest(chest_id: int) -> void:
	_opened_chests[chest_id] = true


func is_chest_opened(chest_id: int) -> bool:
	return _opened_chests.has(chest_id)


func take_loot(loot_cell: Vector2i) -> void:
	_taken_loot[loot_cell] = true


func is_loot_taken(loot_cell: Vector2i) -> bool:
	return _taken_loot.has(loot_cell)


## Every cell the hero has seen on the map (see Exploration).
func remember_explored(cells: Array[Vector2i]) -> void:
	_explored = cells.duplicate()


func explored_cells() -> Array[Vector2i]:
	return _explored.duplicate()


## Everything lying on the floor that the map didn't start with, as the hero left it.
func remember_dropped(items: Array[DroppedItem]) -> void:
	_dropped = items.duplicate()


func dropped_items() -> Array[DroppedItem]:
	return _dropped.duplicate()


## The monsters left hurt (spawn cell -> health) at run time left_at; the rest are at full health.
func remember_hurt(health_by_enemy: Dictionary, left_at: float) -> void:
	_hurt.clear()
	for enemy_id: Vector2i in health_by_enemy:
		_hurt[enemy_id] = {"health": health_by_enemy[enemy_id], "left_at": left_at}


## A monster's health on coming back at run time now: what it was left with, healed for the time away (see
## Regeneration), or max_health if it was never hurt.
func health_on_return(enemy_id: Vector2i, max_health: int, now: float, health_per_second: float) -> int:
	if not _hurt.has(enemy_id):
		return max_health
	var left: Dictionary = _hurt[enemy_id]
	return Regeneration.healed(left.health, max_health, now - left.left_at, health_per_second)


## A campfire as the hero left it: its state and the seconds it has left (its burn, or its embers' countdown).
## Those only count down while the hero is on the map, so this is all a return needs.
func remember_campfire(cell: Vector2i, campfire: Campfire) -> void:
	_campfires[cell] = {"state": campfire.state, "seconds_left": campfire.seconds_left()}


## The campfire at a cell as it was left (unlit if it was never lit), by the rest profile it follows.
func campfire_at(cell: Vector2i, profile: RestProfile) -> Campfire:
	if not _campfires.has(cell):
		return Campfire.new(profile)
	var left: Dictionary = _campfires[cell]
	return Campfire.new(profile, left.state as Campfire.State, left.seconds_left)


## How many times the campfire at a cell has been lit. Each lighting makes one ambush roll (see Ambush), so this
## is also the number of rolls spent there; a lighting's roll is never made twice.
func lightings_of(cell: Vector2i) -> int:
	return _lightings.get(cell, 0)


## The campfire at a cell is being lit: spends its next ambush roll and returns that lighting's number (0 for the
## first time), which is what the roll is seeded by.
func spend_lighting(cell: Vector2i) -> int:
	var lighting := lightings_of(cell)
	_lightings[cell] = lighting + 1
	return lighting


func to_dict() -> Dictionary:
	var hurt := []
	for enemy_id: Vector2i in _hurt:
		hurt.append({"enemy": _cell_to_data(enemy_id), "health": _hurt[enemy_id].health,
			"left_at": _hurt[enemy_id].left_at})
	var dropped := []
	for item in _dropped:
		dropped.append({"item": item.item_id, "potion": item.is_potion,
			"position": [item.position.x, item.position.y]})
	var campfires := []
	for cell: Vector2i in _campfires:
		campfires.append({"cell": _cell_to_data(cell), "state": _campfires[cell].state,
			"seconds_left": _campfires[cell].seconds_left})
	var lightings := []
	for cell: Vector2i in _lightings:
		lightings.append({"cell": _cell_to_data(cell), "count": _lightings[cell]})
	return {
		"generator_version": generator_version,
		"killed": _cells_to_data(_killed.keys()),
		"opened_chests": _opened_chests.keys(),
		"taken_loot": _cells_to_data(_taken_loot.keys()),
		"explored": _cells_to_data(_explored),
		"dropped": dropped,
		"hurt": hurt,
		"lich_dead": _lich_dead,
		"campfires": campfires,
		"lightings": lightings,
	}


## A record from to_dict's dictionary (or the same read back from JSON, where every number is a float).
static func from_dict(data: Dictionary) -> MapRecord:
	var record := MapRecord.new(int(data.get("generator_version", 0)))
	for cell in _cells_from_data(data.get("killed", [])):
		record.kill(cell)
	for chest_id: Variant in data.get("opened_chests", []):
		record.open_chest(int(chest_id))
	for cell in _cells_from_data(data.get("taken_loot", [])):
		record.take_loot(cell)
	record.remember_explored(_cells_from_data(data.get("explored", [])))
	var dropped: Array[DroppedItem] = []
	for item: Dictionary in data.get("dropped", []):
		var at: Array = item.position
		dropped.append(DroppedItem.new(item.item, item.potion, Vector2(at[0], at[1])))
	record.remember_dropped(dropped)
	if data.get("lich_dead", false):
		record.kill_lich()
	for left: Dictionary in data.get("hurt", []):
		record._hurt[_cell_from_data(left.enemy)] = {"health": int(left.health), "left_at": float(left.left_at)}
	for fire: Dictionary in data.get("campfires", []):
		record._campfires[_cell_from_data(fire.cell)] = {
			"state": int(fire.state), "seconds_left": float(fire.seconds_left)}
	for lit: Dictionary in data.get("lightings", []):
		record._lightings[_cell_from_data(lit.cell)] = int(lit.count)
	return record


static func _cell_to_data(cell: Vector2i) -> Array:
	return [cell.x, cell.y]


static func _cell_from_data(data: Array) -> Vector2i:
	return Vector2i(int(data[0]), int(data[1]))


static func _cells_to_data(cells: Array) -> Array:
	return cells.map(_cell_to_data)


static func _cells_from_data(data: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for each: Array in data:
		cells.append(_cell_from_data(each))
	return cells
