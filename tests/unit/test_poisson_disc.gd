extends GutTest
## Points spread evenly but with no pattern: never too close, never leaving a wide gap.

const AREA := Rect2i(10, 20, 60, 40)
const SPACING := 5.0


func _sample(seed_value: int, area := AREA, spacing := SPACING) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return PoissonDisc.sample(area, spacing, rng)


func test_every_point_lies_inside_the_area() -> void:
	for cell in _sample(1):
		assert_true(AREA.has_point(cell), str(cell))


func test_no_two_points_are_much_closer_than_the_spacing() -> void:
	var cells := _sample(2)

	for i in cells.size():
		for j in range(i + 1, cells.size()):
			# Points are rounded down to cells, so two may be up to one cell's diagonal closer.
			assert_gte(Vector2(cells[i]).distance_to(Vector2(cells[j])), SPACING - sqrt(2.0))


func test_the_points_leave_no_wide_gap() -> void:
	var cells := _sample(3)

	for y in range(AREA.position.y, AREA.end.y, 3):
		for x in range(AREA.position.x, AREA.end.x, 3):
			var nearest := INF
			for cell in cells:
				nearest = minf(nearest, Vector2(cell).distance_to(Vector2(x, y)))
			assert_lte(nearest, SPACING * 2.0 + 1.0, "gap round %s" % Vector2i(x, y))


func test_the_same_random_numbers_give_the_same_points() -> void:
	assert_eq(_sample(4), _sample(4))


func test_different_random_numbers_give_different_points() -> void:
	assert_ne(_sample(4), _sample(5))


func test_an_empty_area_gives_no_points() -> void:
	assert_eq(_sample(6, Rect2i(0, 0, 0, 10)).size(), 0)
