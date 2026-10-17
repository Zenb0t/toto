class_name PotionBelt
extends RefCounted
## The potions the player carries: how many of each kind, up to a limit per kind. Pure.

signal changed

const DEFAULT_CAPACITY := 3

## How many of one kind fit in the belt.
var capacity := DEFAULT_CAPACITY

var _counts := {}  # potion id -> int, only for kinds held


## Takes one potion. False (and nothing changes) when that kind is already full.
func add(potion_id: String) -> bool:
	if count(potion_id) >= capacity:
		return false
	_counts[potion_id] = count(potion_id) + 1
	changed.emit()
	return true


## Uses up one potion. False when there is none of that kind.
func take(potion_id: String) -> bool:
	if count(potion_id) == 0:
		return false
	_counts[potion_id] -= 1
	if _counts[potion_id] == 0:
		_counts.erase(potion_id)
	changed.emit()
	return true


func count(potion_id: String) -> int:
	return _counts.get(potion_id, 0)


func has_room_for(potion_id: String) -> bool:
	return count(potion_id) < capacity


## The kinds held, in the order given (so the belt's buttons keep their places).
func held_ids(order: Array[String]) -> Array[String]:
	var held: Array[String] = []
	for id in order:
		if count(id) > 0:
			held.append(id)
	return held


func to_dict() -> Dictionary:
	return _counts.duplicate()


func load_dict(counts: Dictionary) -> void:
	_counts.clear()
	for id: String in counts:
		if counts[id] > 0:
			_counts[id] = mini(int(counts[id]), capacity)
	changed.emit()
