extends GutTest

const STEP := 0.1


func _senses(has_target := true, sees_target := true, has_turn := false, winding_up := false) -> EnemyBrain.Senses:
	var senses := EnemyBrain.Senses.new()
	senses.has_target = has_target
	senses.sees_target = sees_target
	senses.has_turn = has_turn
	senses.winding_up = winding_up
	return senses


## A brain that has just attacked and is stepping aside.
func _recovering(recover_seconds: float) -> EnemyBrain:
	var brain := EnemyBrain.new()
	brain.recover_seconds = recover_seconds
	brain.update(STEP, _senses())
	brain.update(STEP, _senses(true, true, true))
	brain.update(STEP, _senses())
	return brain


func test_an_enemy_without_a_target_stays_idle() -> void:
	var brain := EnemyBrain.new()

	assert_eq(brain.update(STEP, _senses(false)), EnemyBrain.State.IDLE)


func test_an_enemy_that_sees_its_target_takes_up_position() -> void:
	var brain := EnemyBrain.new()

	assert_eq(brain.update(STEP, _senses(true, true)), EnemyBrain.State.POSITION)


func test_an_enemy_that_cannot_see_its_target_hunts_for_it() -> void:
	var brain := EnemyBrain.new()

	assert_eq(brain.update(STEP, _senses(true, false)), EnemyBrain.State.HUNT)


func test_a_hunter_that_spots_its_target_takes_up_position() -> void:
	var brain := EnemyBrain.new()
	brain.update(STEP, _senses(true, false))

	assert_eq(brain.update(STEP, _senses(true, true)), EnemyBrain.State.POSITION)


func test_an_enemy_given_its_turn_winds_up_an_attack() -> void:
	var brain := EnemyBrain.new()
	brain.update(STEP, _senses())

	assert_eq(brain.update(STEP, _senses(true, true, true)), EnemyBrain.State.WINDUP)


func test_a_hunter_with_a_lobbing_weapon_attacks_from_out_of_sight() -> void:
	var brain := EnemyBrain.new()
	brain.update(STEP, _senses(true, false))

	assert_eq(brain.update(STEP, _senses(true, false, true)), EnemyBrain.State.WINDUP)


func test_an_enemy_keeps_winding_up_while_its_attack_is_coming() -> void:
	var brain := EnemyBrain.new()
	brain.update(STEP, _senses())
	brain.update(STEP, _senses(true, true, true))

	assert_eq(brain.update(STEP, _senses(true, true, false, true)), EnemyBrain.State.WINDUP)


func test_an_enemy_finishes_its_wind_up_even_if_the_target_is_gone() -> void:
	var brain := EnemyBrain.new()
	brain.update(STEP, _senses())
	brain.update(STEP, _senses(true, true, true))

	assert_eq(brain.update(STEP, _senses(false, false, false, true)), EnemyBrain.State.WINDUP)


func test_after_attacking_an_enemy_steps_aside_to_recover() -> void:
	var brain := _recovering(0.5)

	assert_eq(brain.state, EnemyBrain.State.RECOVER)
	assert_false(brain.is_looking_for_a_turn())


func test_a_recovering_enemy_goes_back_to_its_position_once_recovered() -> void:
	var brain := _recovering(0.25)

	var early := brain.update(0.2, _senses())
	var late := brain.update(0.1, _senses())

	assert_eq(early, EnemyBrain.State.RECOVER)
	assert_eq(late, EnemyBrain.State.POSITION)


func test_an_enemy_that_lost_its_target_goes_idle() -> void:
	var brain := EnemyBrain.new()
	brain.update(STEP, _senses())

	assert_eq(brain.update(STEP, _senses(false)), EnemyBrain.State.IDLE)


func test_only_hunting_or_positioned_enemies_look_for_a_turn() -> void:
	var brain := EnemyBrain.new()
	var idle := brain.is_looking_for_a_turn()
	brain.update(STEP, _senses())

	assert_false(idle)
	assert_true(brain.is_looking_for_a_turn())
