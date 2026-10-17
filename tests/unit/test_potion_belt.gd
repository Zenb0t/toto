extends GutTest


func test_a_new_belt_holds_nothing() -> void:
	var belt := PotionBelt.new()

	assert_eq(belt.count("healing"), 0)
	assert_false(belt.take("healing"))


func test_potions_stack_by_kind() -> void:
	var belt := PotionBelt.new()

	belt.add("healing")
	belt.add("healing")
	belt.add("haste")

	assert_eq(belt.count("healing"), 2)
	assert_eq(belt.count("haste"), 1)


func test_drinking_uses_one_up() -> void:
	var belt := PotionBelt.new()
	belt.add("healing")
	belt.add("healing")

	assert_true(belt.take("healing"))

	assert_eq(belt.count("healing"), 1)


func test_a_full_kind_takes_no_more() -> void:
	var belt := PotionBelt.new()
	belt.capacity = 2
	belt.add("might")
	belt.add("might")

	assert_false(belt.add("might"))
	assert_false(belt.has_room_for("might"))
	assert_eq(belt.count("might"), 2)
	assert_true(belt.has_room_for("haste"), "other kinds still fit")


func test_the_kinds_held_keep_the_order_given() -> void:
	var belt := PotionBelt.new()
	belt.add("might")
	belt.add("healing")

	assert_eq(belt.held_ids(["healing", "haste", "might"]), ["healing", "might"] as Array[String])


func test_it_announces_every_change() -> void:
	var belt := PotionBelt.new()
	watch_signals(belt)

	belt.add("healing")
	belt.take("healing")

	assert_signal_emit_count(belt, "changed", 2)


func test_it_can_be_saved_and_restored() -> void:
	var belt := PotionBelt.new()
	belt.add("haste")
	belt.add("haste")
	var restored := PotionBelt.new()

	restored.load_dict(belt.to_dict())

	assert_eq(restored.count("haste"), 2)
