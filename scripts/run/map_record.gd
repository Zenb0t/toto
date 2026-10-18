class_name MapRecord
extends RefCounted
## What the hero changed on one map, so the map can be thrown away on leaving and made again from its seed on
## return, the way it was left: monsters killed, chests opened, floor items taken, items dropped, cells explored
## and monsters left hurt. Things are known by where the map puts them (an enemy by its spawn cell, a floor item
## by its loot cell, a chest by its room), which is what lets a record match its regenerated map.
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
var _opened_chests := {}  # int (room) -> true
var _taken_loot := {}  # Vector2i (loot cell) -> true
var _explored: Array[Vector2i] = []
var _dropped: Array[DroppedItem] = []
var _hurt := {}  # Vector2i (spawn cell) -> {"health": int, "left_at": float}


func _init(made_by_version: int) -> void:
	generator_version = made_by_version


func kill(enemy_id: Vector2i) -> void:
	_killed[enemy_id] = true
	_hurt.erase(enemy_id)


func is_killed(enemy_id: Vector2i) -> bool:
	return _killed.has(enemy_id)


func open_chest(room: int) -> void:
	_opened_chests[room] = true


func is_chest_opened(room: int) -> bool:
	return _opened_chests.has(room)


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


func to_dict() -> Dictionary:
	var hurt := []
	for enemy_id: Vector2i in _hurt:
		hurt.append({"enemy": _cell_to_data(enemy_id), "health": _hurt[enemy_id].health,
			"left_at": _hurt[enemy_id].left_at})
	var dropped := []
	for item in _dropped:
		dropped.append({"item": item.item_id, "potion": item.is_potion,
			"position": [item.position.x, item.position.y]})
	return {
		"generator_version": generator_version,
		"killed": _cells_to_data(_killed.keys()),
		"opened_chests": _opened_chests.keys(),
		"taken_loot": _cells_to_data(_taken_loot.keys()),
		"explored": _cells_to_data(_explored),
		"dropped": dropped,
		"hurt": hurt,
	}


## A record from to_dict's dictionary (or the same read back from JSON, where every number is a float).
static func from_dict(data: Dictionary) -> MapRecord:
	var record := MapRecord.new(int(data.get("generator_version", 0)))
	for cell in _cells_from_data(data.get("killed", [])):
		record.kill(cell)
	for room: Variant in data.get("opened_chests", []):
		record.open_chest(int(room))
	for cell in _cells_from_data(data.get("taken_loot", [])):
		record.take_loot(cell)
	record.remember_explored(_cells_from_data(data.get("explored", [])))
	var dropped: Array[DroppedItem] = []
	for item: Dictionary in data.get("dropped", []):
		var at: Array = item.position
		dropped.append(DroppedItem.new(item.item, item.potion, Vector2(at[0], at[1])))
	record.remember_dropped(dropped)
	for left: Dictionary in data.get("hurt", []):
		record._hurt[_cell_from_data(left.enemy)] = {"health": int(left.health), "left_at": float(left.left_at)}
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
