extends GutTest

const PLAYER := Vector2.ZERO


func test_picks_the_closest_enemy() -> void:
	var enemies: Array[Vector2] = [Vector2(300, 0), Vector2(0, 120), Vector2(-200, 0)]

	assert_eq(AutoAim.nearest_index(PLAYER, enemies, 1000.0), 1)


func test_ignores_enemies_beyond_range() -> void:
	var enemies: Array[Vector2] = [Vector2(500, 0)]

	assert_eq(AutoAim.nearest_index(PLAYER, enemies, 400.0), AutoAim.NO_TARGET)


func test_no_enemies_means_no_target() -> void:
	var enemies: Array[Vector2] = []

	assert_eq(AutoAim.nearest_index(PLAYER, enemies, 400.0), AutoAim.NO_TARGET)
