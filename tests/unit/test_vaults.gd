extends GutTest

const BOUNDS := Rect2i(3, 3, 24, 16)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _rows(vault_name: String) -> PackedStringArray:
	return Vaults.DESIGNS[vault_name].strip_edges().split("\n")


func test_every_vault_is_drawn_at_its_declared_size() -> void:
	for vault_name: String in Vaults.DESIGNS:
		var rows := _rows(vault_name)
		assert_eq(rows.size(), Vaults.SIZE.y, vault_name)
		for row in rows:
			assert_eq(row.length(), Vaults.SIZE.x, vault_name)


func test_every_vault_has_a_floor_ring_for_corridors_to_open_onto() -> void:
	for vault_name: String in Vaults.DESIGNS:
		var rows := _rows(vault_name)
		for x in Vaults.SIZE.x:
			assert_eq(rows[0][x], ".", vault_name)
			assert_eq(rows[-1][x], ".", vault_name)
		for row in rows:
			assert_eq(row[0], ".", vault_name)
			assert_eq(row[-1], ".", vault_name)


func test_every_walkable_spot_in_a_vault_can_be_reached() -> void:
	for vault_name: String in Vaults.DESIGNS:
		var map := DungeonMapParser.new().parse(_framed(vault_name))
		var reached := {map.player_spawn: true}
		var frontier: Array[Vector2i] = [map.player_spawn]
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + step
				if map.is_walkable(next) and not reached.has(next):
					reached[next] = true
					frontier.append(next)
		assert_eq(reached.size(), map.walkable_cells().size(), vault_name)


func test_a_stamped_vault_sits_inside_its_bounds() -> void:
	for vault_name: String in Vaults.DESIGNS:
		for cell: Vector2i in Vaults.stamp(vault_name, BOUNDS, _rng(1)):
			assert_true(BOUNDS.has_point(cell), "%s %s" % [vault_name, cell])


func test_stamping_mirrors_vaults_for_variety() -> void:
	var layouts := {}
	for seed_value in 12:
		var stamped := Vaults.stamp("treasure_closet", BOUNDS, _rng(seed_value))
		var door: Vector2i = stamped.keys().filter(func(cell: Vector2i) -> bool: return stamped[cell] == "+")[0]
		layouts[door] = true

	assert_gt(layouts.size(), 1)


## The Dungeon branch (no longer the descent) has water-filled vaults.
func test_vaults_show_up_in_generated_dungeons() -> void:
	var with_water_or_lava := 0
	for seed_value in 20:
		var map := DungeonMapParser.new().parse(DungeonGenerator.new().generate(seed_value, 1, CryptRecipe.new(), Branch.for_floor(1)))
		if not map.cells_with(DungeonMap.Terrain.WATER).is_empty() or not map.cells_with(DungeonMap.Terrain.LAVA).is_empty():
			with_water_or_lava += 1

	assert_gt(with_water_or_lava, 3)


## The vault inside walls, with the player at its top-left corner.
func _framed(vault_name: String) -> String:
	var rows := _rows(vault_name)
	var lines: Array[String] = ["#".repeat(Vaults.SIZE.x + 2)]
	for y in rows.size():
		var row := rows[y]
		if y == 0:
			row = "P" + row.substr(1)
		lines.append("#" + row + "#")
	lines.append("#".repeat(Vaults.SIZE.x + 2))
	return "\n".join(lines)
