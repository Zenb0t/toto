extends GutTest

var _puppets: Puppets


func before_each() -> void:
	_puppets = Puppets.new()
	add_child_autofree(_puppets)


func _actor_at(position: Vector2) -> Node2D:
	var actor := Node2D.new()
	actor.position = position
	add_child_autofree(actor)
	return actor


func test_a_model_stands_where_its_actor_is() -> void:
	var model := Node3D.new()

	_puppets.add(_actor_at(Vector2(64, 96)), model)

	assert_eq(model.position, Vector3(2, 0, 3))


func test_a_model_follows_its_actor_around() -> void:
	var actor := _actor_at(Vector2.ZERO)
	var model := Node3D.new()
	_puppets.add(actor, model)

	actor.position = Vector2(32, 160)
	await wait_process_frames(1)

	assert_eq(model.position, Vector3(1, 0, 5))


func test_a_model_is_hidden_while_its_actor_is() -> void:
	var actor := _actor_at(Vector2.ZERO)
	var model := Node3D.new()
	_puppets.add(actor, model)

	actor.hide()
	await wait_process_frames(1)

	assert_false(model.visible)


func test_a_model_goes_away_with_its_actor() -> void:
	var actor := _actor_at(Vector2.ZERO)
	var model := Node3D.new()
	_puppets.add(actor, model)

	actor.queue_free()
	await wait_process_frames(2)

	assert_eq(_puppets.count(), 0)
	assert_false(is_instance_valid(model))


func test_a_model_waits_hidden_for_an_actor_placed_late() -> void:
	var actor: Node2D = autofree(Node2D.new())
	var model := Node3D.new()

	_puppets.add(actor, model)

	assert_false(model.visible)


func test_the_pose_copies_what_the_actor_shows() -> void:
	var chest := Chest.new()
	add_child_autofree(chest)
	var model := ChestModel.new()
	_puppets.add(chest, model, func(shown: ChestModel) -> void: shown.show_open(chest.is_open()))
	assert_false(model.is_shown_open())

	chest.player_entered.emit()
	await wait_process_frames(1)

	assert_true(model.is_shown_open())


func test_a_released_model_stays_when_its_actor_goes() -> void:
	var actor := _actor_at(Vector2(32, 32))
	var model := Node3D.new()
	_puppets.add(actor, model)

	assert_eq(_puppets.release(actor), model)
	actor.queue_free()
	await wait_process_frames(2)

	assert_true(is_instance_valid(model))
	assert_eq(_puppets.count(), 0)
