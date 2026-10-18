extends GutTest
## A campfire in the world with the real hero: standing in its light heals them up to half, and a hit ends it.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CELL := DungeonView.TILE_SIZE

var _profile := RestProfile.campfire()


func _hero_with(health: int) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.health = Health.restored(Player.MAX_HEALTH, health)
	add_child_autofree(player)
	return player


func _lit_spot_for(player: Player) -> RestSpot:
	var spot := RestSpot.new(Campfire.new(_profile), Vector2.ZERO)
	add_child_autofree(spot)
	spot.attend(player)
	spot.fire.light()
	return spot


func test_standing_in_the_light_heals_the_hero_up_to_half_their_health() -> void:
	var player := _hero_with(100)
	player.position = Vector2(CELL, 0)
	_lit_spot_for(player)

	await wait_seconds(_profile.burn_seconds + 0.5)

	assert_eq(player.health.current, Player.MAX_HEALTH / 2)


func test_a_hit_stops_the_healing() -> void:
	var player := _hero_with(100)
	player.position = Vector2(CELL, 0)
	_lit_spot_for(player)
	await wait_seconds(1.0)

	player.take_damage(10)
	var after_hit := player.health.current
	await wait_seconds(2.0)

	assert_eq(player.health.current, after_hit)
	assert_gt(after_hit, 100, "it had healed before")


func test_an_attack_stops_the_healing() -> void:
	var player := _hero_with(100)
	player.position = Vector2(CELL, 0)
	_lit_spot_for(player)
	await wait_seconds(0.5)

	player.attack(Vector2.RIGHT)
	await wait_for_signal(player.attack_fired, 2.0)
	var after_attack := player.health.current
	await wait_seconds(2.0)

	assert_eq(player.health.current, after_attack)


func test_a_hero_out_of_the_light_is_not_healed() -> void:
	var player := _hero_with(100)
	player.position = Vector2((_profile.light_radius_cells + 3.0) * CELL, 0)
	var spot := _lit_spot_for(player)

	await wait_seconds(1.0)

	assert_eq(player.health.current, 100)
	assert_eq(spot.fire.state, Campfire.State.BURNING, "the fire burns on")


func test_stepping_back_into_the_light_carries_on_healing() -> void:
	var player := _hero_with(100)
	player.position = Vector2((_profile.light_radius_cells + 3.0) * CELL, 0)
	_lit_spot_for(player)
	await wait_seconds(0.5)

	player.position = Vector2(CELL, 0)
	await wait_seconds(1.0)

	assert_gt(player.health.current, 100)
