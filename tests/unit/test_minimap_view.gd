extends GutTest
## The minimap keeps its picture: a step repaints only what it changed, and the picture stays the one a whole
## repaint would give.

## A long hall, with a wall across it that has a door-sized gap, and a pool.
const WIDTH := 60


func _hall() -> DungeonMap:
	var rows := PackedStringArray([
		"#".repeat(WIDTH),
		"#P" + ".".repeat(28) + "#" + ".".repeat(WIDTH - 32) + "#",
		"#" + ".".repeat(10) + "~~" + ".".repeat(WIDTH - 14) + "#",
		"#" + ".".repeat(28) + "#" + ".".repeat(WIDTH - 31) + "#",
		"#".repeat(WIDTH),
	])
	return DungeonMapParser.new().parse("\n".join(rows))


func _assert_same_picture(actual: Image, expected: Image) -> void:
	assert_eq(actual.get_size(), expected.get_size())
	for y in expected.get_height():
		for x in expected.get_width():
			if actual.get_pixel(x, y) != expected.get_pixel(x, y):
				fail_test("pixel (%d, %d) is %s, should be %s" % [x, y, actual.get_pixel(x, y), expected.get_pixel(x, y)])
				return
	pass_test("same picture")


func test_walking_repaints_the_same_picture_as_painting_it_whole() -> void:
	var map := _hall()
	var minimap: MinimapView = autofree(MinimapView.new())
	var exploration := Exploration.new()
	exploration.look_from(map.player_spawn, map.is_see_through)
	minimap.show_map(map, exploration, map.player_spawn)

	var cell := map.player_spawn
	for step in [Vector2i(10, 1), Vector2i(25, 2), Vector2i(29, 2), Vector2i(45, 3), Vector2i(57, 1)]:
		cell = step
		exploration.look_from(cell, map.is_see_through)
		minimap.show_changes(map, exploration, cell)

	_assert_same_picture(minimap.picture(), MinimapPainter.paint(map, exploration, cell))


func test_the_player_mark_moves_with_the_player() -> void:
	var map := _hall()
	var minimap: MinimapView = autofree(MinimapView.new())
	var exploration := Exploration.new()
	exploration.look_from(map.player_spawn, map.is_see_through)
	minimap.show_map(map, exploration, map.player_spawn)

	exploration.look_from(Vector2i(3, 1), map.is_see_through)
	minimap.show_changes(map, exploration, Vector2i(3, 1))

	assert_true(_is_player_mark(minimap.picture().get_pixelv(Vector2i(3, 1))))
	assert_false(_is_player_mark(minimap.picture().get_pixelv(map.player_spawn)), "no mark left behind")


## Pixels hold 8 bits per channel, so colours come back a hair off.
func _is_player_mark(pixel: Color) -> bool:
	var mark := MinimapPainter.PLAYER_COLOR
	return absf(pixel.r - mark.r) + absf(pixel.g - mark.g) + absf(pixel.b - mark.b) < 0.02
