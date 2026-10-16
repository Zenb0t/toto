extends GutTest

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const LOOT_CARD_SCENE := preload("res://scenes/ui/loot_card.tscn")
const FAR_AWAY := Vector2(500, 0)


func _spawn_player_at(position: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = position
	add_child_autofree(player)
	return player


func _place(area: PickupArea) -> PickupArea:
	add_child_autofree(area)
	return area


func test_walking_onto_a_chest_opens_it() -> void:
	var chest: Chest = _place(Chest.new())
	watch_signals(chest)

	_spawn_player_at(Vector2.ZERO)
	await wait_physics_frames(3)

	assert_true(chest.is_open())
	assert_signal_emitted(chest, "opened")


func test_a_chest_stays_shut_while_the_player_is_elsewhere() -> void:
	var chest: Chest = _place(Chest.new())
	watch_signals(chest)

	_spawn_player_at(FAR_AWAY)
	await wait_physics_frames(3)

	assert_false(chest.is_open())


func test_an_enemy_cannot_open_a_chest() -> void:
	var chest: Chest = _place(Chest.new())
	watch_signals(chest)

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	add_child_autofree(enemy)
	await wait_physics_frames(3)

	assert_false(chest.is_open())


func test_a_chest_only_opens_once() -> void:
	var chest: Chest = _place(Chest.new())
	watch_signals(chest)
	var player := _spawn_player_at(Vector2.ZERO)
	await wait_physics_frames(3)

	player.position = FAR_AWAY
	await wait_physics_frames(3)
	player.position = Vector2.ZERO
	await wait_physics_frames(3)

	assert_signal_emit_count(chest, "opened", 1)


func test_a_dropped_weapon_notices_the_player_stepping_on_and_off() -> void:
	var drop: WeaponDrop = _place(WeaponDrop.new(Sword.new()))
	watch_signals(drop)
	var player := _spawn_player_at(Vector2.ZERO)
	await wait_physics_frames(3)

	player.position = FAR_AWAY
	await wait_physics_frames(3)

	assert_signal_emitted(drop, "player_entered")
	assert_signal_emitted(drop, "player_exited")


func _loot_card() -> LootCard:
	var card: LootCard = LOOT_CARD_SCENE.instantiate()
	add_child_autofree(card)
	return card


func test_the_loot_card_is_hidden_until_something_is_offered() -> void:
	assert_false(_loot_card().visible)


func test_the_loot_card_compares_the_found_weapon_with_the_held_one() -> void:
	var card := _loot_card()

	card.show_offer(Fireball.new(), Wand.new())

	assert_true(card.visible)
	assert_eq(card.get_node("Panel/Rows/FoundName").text, "Fireball")
	assert_eq(card.get_node("Panel/Rows/FoundDescription").text, Fireball.new().description)
	assert_eq(card.get_node("Panel/Rows/Replaces").text, "Replaces your Wand")


func test_the_loot_card_reports_take_and_leave() -> void:
	var card := _loot_card()
	card.show_offer(Sword.new(), Wand.new())
	watch_signals(card)

	card.get_node("Panel/Rows/Buttons/Take").pressed.emit()
	card.get_node("Panel/Rows/Buttons/Leave").pressed.emit()

	assert_signal_emitted(card, "take_pressed")
	assert_signal_emitted(card, "leave_pressed")
