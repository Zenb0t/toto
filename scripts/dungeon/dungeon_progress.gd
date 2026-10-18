class_name DungeonProgress
extends RefCounted
## Room rules: which rooms still have enemies, and the lock. Walking into a locking room (a trap room, a boss
## arena) that still has enemies locks you in until they are all defeated. Ordinary rooms never lock: their
## monsters come for you when they notice you (see Awareness).

signal room_locked(room: int)
signal room_cleared(room: int)
signal dungeon_cleared

const NO_ROOM := -1

var locked_room := NO_ROOM
var _enemies_left_by_room: Dictionary  # int -> int
var _locking_rooms := {}  # int -> true


## enemies_by_room maps each room id to how many enemies start in it; locking_rooms are the rooms that lock.
func _init(enemies_by_room: Dictionary, locking_rooms: Array[int] = []) -> void:
	_enemies_left_by_room = enemies_by_room.duplicate()
	for room in locking_rooms:
		_locking_rooms[room] = true


func enemies_left_in(room: int) -> int:
	return _enemies_left_by_room.get(room, 0)


func total_enemies_left() -> int:
	var total := 0
	for count: int in _enemies_left_by_room.values():
		total += count
	return total


func is_cleared(room: int) -> bool:
	return enemies_left_in(room) == 0


func is_locking(room: int) -> bool:
	return _locking_rooms.has(room)


func enter_room(room: int) -> void:
	if locked_room != NO_ROOM or not is_locking(room) or is_cleared(room):
		return
	locked_room = room
	room_locked.emit(room)


func record_defeat(room: int) -> void:
	if is_cleared(room):
		return
	_enemies_left_by_room[room] -= 1
	if not is_cleared(room):
		return
	if locked_room == room:
		locked_room = NO_ROOM
	room_cleared.emit(room)
	if total_enemies_left() == 0:
		dungeon_cleared.emit()
