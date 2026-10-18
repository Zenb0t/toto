extends GutTest
## The inn's rest in the world with the real hero: three seconds on the doorstep heal them fully; moving or a hit
## cancels it; the offer only exists on the doorstep.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CELL := DungeonView.TILE_SIZE

var _ended: Array[bool] = []


func _hero_with(health: int) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.health = Health.restored(Player.MAX_HEALTH, health)
	add_child_autofree(player)
	return player


func _inn_for(player: Player) -> InnSpot:
	var spot := InnSpot.new(InnRest.new(), Vector2.ZERO)
	add_child_autofree(spot)
	spot.attend(player)
	spot.rest_ended.connect(func(completed: bool) -> void: _ended.append(completed))
	return spot


func before_each() -> void:
	_ended.clear()


func test_three_seconds_on_the_doorstep_heal_the_hero_fully() -> void:
	var player := _hero_with(100)
	var inn := _inn_for(player)
	inn.rest.begin()

	await wait_seconds(3.5)

	assert_eq(player.health.current, Player.MAX_HEALTH)
	assert_eq(_ended, [true])


func test_the_hero_is_not_healed_before_the_rest_is_over() -> void:
	var player := _hero_with(100)
	var inn := _inn_for(player)
	inn.rest.begin()

	await wait_seconds(1.5)

	assert_eq(player.health.current, 100)


func test_moving_cancels_the_rest_and_heals_nothing() -> void:
	var player := _hero_with(100)
	var inn := _inn_for(player)
	inn.rest.begin()
	await wait_seconds(1.0)

	player.move(Vector2.RIGHT)
	await wait_seconds(0.3)
	player.move(Vector2.ZERO)
	await wait_seconds(3.0)

	assert_eq(_ended, [false])
	assert_eq(player.health.current, 100)


func test_leaving_the_doorstep_without_steering_cancels_the_rest() -> void:
	var player := _hero_with(100)
	var inn := _inn_for(player)
	inn.rest.begin()
	await wait_seconds(1.0)

	player.position = Vector2(CELL * 4, 0)  # carried off, as by a blink, with no stick held
	await wait_seconds(3.0)

	assert_eq(_ended, [false])
	assert_eq(player.health.current, 100)


func test_a_hit_cancels_the_rest() -> void:
	var player := _hero_with(500)
	var inn := _inn_for(player)
	inn.rest.begin()
	await wait_seconds(1.0)

	player.take_damage(10)
	await wait_seconds(3.0)

	assert_eq(_ended, [false])
	assert_eq(player.health.current, 490)


func test_the_hero_can_rest_again_at_once_after_a_cancelled_rest() -> void:
	var player := _hero_with(500)
	var inn := _inn_for(player)
	inn.rest.begin()
	await wait_seconds(0.5)
	player.take_damage(10)

	assert_true(inn.rest.begin())
	await wait_seconds(3.5)

	assert_eq(player.health.current, Player.MAX_HEALTH)


func test_the_rest_is_on_offer_only_on_the_doorstep() -> void:
	var player := _hero_with(100)
	var inn := _inn_for(player)

	player.position = Vector2(CELL * 0.5, 0)
	assert_true(inn.is_within_reach(), "on the doorstep")
	player.position = Vector2(CELL * 3, 0)
	assert_false(inn.is_within_reach(), "a few cells off")
