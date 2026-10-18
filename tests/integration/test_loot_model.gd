extends GutTest
## Things on the floor show a model, or a glowing placeholder when a weapon has none.


func _loot() -> LootModel:
	var loot := LootModel.new()
	add_child_autofree(loot)
	return loot


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count


func test_knuckles_on_the_floor_show_a_placeholder_and_their_name() -> void:
	var loot := _loot()
	var knuckles := Knuckles.new()

	loot.show_item(knuckles)

	assert_eq(loot.shown_label(), knuckles.button_label)
	assert_gt(_count_meshes(loot), 0, "something visible floats above the floor")


func test_a_weapon_with_a_model_shows_that_model() -> void:
	var loot := _loot()
	var sword := Sword.new()

	loot.show_item(sword)

	assert_eq(loot.shown_label(), sword.button_label)
	assert_gt(_count_meshes(loot), 0)
	assert_true(WeaponModel.has_model(sword.id))


func test_fists_are_the_only_weapon_without_a_model() -> void:
	assert_false(WeaponModel.has_model("knuckles"))
	assert_true(WeaponModel.has_model("bow"))
