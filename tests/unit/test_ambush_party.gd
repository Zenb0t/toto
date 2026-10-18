extends GutTest
## An ambush on its way arrives once, after its delay.


func _party(delay := 4.0) -> AmbushParty:
	var ids: Array[String] = ["kobold", "goblin"]
	var cells: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2)]
	return AmbushParty.new(ids, cells, delay, Vector2i(0, 0))


func test_it_has_not_arrived_before_its_delay_is_up() -> void:
	var party := _party()

	assert_false(party.tick(3.9))


func test_it_arrives_on_the_step_the_delay_runs_out() -> void:
	var party := _party()
	party.tick(3.0)

	assert_true(party.tick(1.5))


func test_it_arrives_only_once() -> void:
	var party := _party()
	party.tick(5.0)

	assert_false(party.tick(1.0))
