extends GutTest


func test_every_monster_has_a_model() -> void:
	for monster in Bestiary.all():
		var look := CharacterLook.of_monster(monster)
		assert_true(ResourceLoader.exists(look.model_path()), monster.id)


func test_every_weapon_has_a_model_in_hand() -> void:
	for weapon_id in GameTuning.weapon_ids():
		var path := CharacterLook.WEAPONS_PATH % CharacterLook.weapon_model(weapon_id)
		assert_true(ResourceLoader.exists(path), weapon_id)


func test_every_weapon_swings_with_an_animation_the_models_have() -> void:
	var animated: Node = load(CharacterLook.hero().model_path()).instantiate()
	var player: AnimationPlayer = animated.find_child("AnimationPlayer", true, false)
	for weapon_id in GameTuning.weapon_ids():
		assert_true(player.has_animation(CharacterLook.attack_animation(weapon_id)), weapon_id)
	animated.free()


func test_races_look_different_from_each_other() -> void:
	var goblin := CharacterLook.of_monster(Bestiary.by_id("goblin"))
	var orc := CharacterLook.of_monster(Bestiary.by_id("orc"))
	var bandit := CharacterLook.of_monster(Bestiary.by_id("bandit"))

	assert_ne(goblin.skin_tint, orc.skin_tint)
	assert_eq(bandit.skin_tint, CharacterLook.NO_TINT, "humans keep their own skin")


func test_casters_dress_as_mages_and_dwarves_are_short() -> void:
	assert_eq(CharacterLook.of_monster(Bestiary.by_id("pyromancer")).model, "Mage")
	assert_lt(CharacterLook.of_monster(Bestiary.by_id("dwarf")).stretch.y, 1.0)


func test_orcs_and_ogres_go_bareheaded_so_their_skin_shows() -> void:
	assert_false(CharacterLook.of_monster(Bestiary.by_id("orc")).wears_hat)
	assert_false(CharacterLook.of_monster(Bestiary.by_id("ogre")).wears_hat)
	assert_true(CharacterLook.of_monster(Bestiary.by_id("dwarf")).wears_hat)


func test_the_undead_are_skeletons_dressed_for_their_weapon() -> void:
	assert_eq(CharacterLook.of_monster(Bestiary.by_id("skeleton_warrior")).model, "Skeleton_Warrior")
	assert_eq(CharacterLook.of_monster(Bestiary.by_id("skeleton_archer")).model, "Skeleton_Rogue")
	assert_eq(CharacterLook.of_monster(Bestiary.by_id("skeletal_mage")).model, "Skeleton_Mage")
