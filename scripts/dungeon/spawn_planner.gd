class_name SpawnPlanner
extends RefCounted
## Decides which floor cells enemies start on. Never plans spawns in the first (player) room.


func plan_enemy_cells(layout: DungeonLayout, seed_value: int, enemies_per_room: int) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var cells: Array[Vector2i] = []
	for room_index in range(1, layout.rooms.size()):
		var room := layout.rooms[room_index]
		for _enemy in enemies_per_room:
			cells.append(_random_cell_inside(room, rng))
	return cells


func _random_cell_inside(room: Rect2i, rng: RandomNumberGenerator) -> Vector2i:
	return Vector2i(
		rng.randi_range(room.position.x, room.end.x - 1),
		rng.randi_range(room.position.y, room.end.y - 1),
	)
