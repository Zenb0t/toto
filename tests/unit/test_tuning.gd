extends GutTest

const SPEED := "speed"
const DELAY := "delay"


func _tuning() -> Tuning:
	var params: Array[Tuning.Param] = [
		Tuning.Param.new(SPEED, "Speed", "Player", 100, 300, 10, 150),
		Tuning.Param.new(DELAY, "Delay", "Weapon", 0.0, 1.0, 0.05, 0.3),
	]
	return Tuning.new(params)


func test_starts_at_the_defaults() -> void:
	var tuning := _tuning()

	assert_eq(tuning.value(SPEED), 150.0)
	assert_eq(tuning.changed_keys(), [] as Array[String])


func test_values_snap_to_the_nearest_step() -> void:
	var tuning := _tuning()

	tuning.set_value(SPEED, 163.0)

	assert_eq(tuning.value(SPEED), 160.0)


func test_values_stay_within_limits() -> void:
	var tuning := _tuning()

	tuning.set_value(SPEED, 9000.0)
	tuning.set_value(DELAY, -1.0)

	assert_eq(tuning.value(SPEED), 300.0)
	assert_eq(tuning.value(DELAY), 0.0)


func test_knows_which_values_were_changed() -> void:
	var tuning := _tuning()

	tuning.set_value(DELAY, 0.5)

	assert_eq(tuning.changed_keys(), ["delay"] as Array[String])


func test_reset_restores_every_default() -> void:
	var tuning := _tuning()
	tuning.set_value(SPEED, 200.0)
	tuning.set_value(DELAY, 0.5)

	tuning.reset()

	assert_eq(tuning.changed_keys(), [] as Array[String])


func test_resetting_some_knobs_leaves_the_others_as_they_were() -> void:
	var tuning := _tuning()
	tuning.set_value(SPEED, 200.0)
	tuning.set_value(DELAY, 0.5)

	tuning.reset_keys([SPEED])

	assert_eq(tuning.changed_keys(), [DELAY] as Array[String])


func test_loading_ignores_unknown_keys_and_broken_values() -> void:
	var tuning := _tuning()

	tuning.load_dict({SPEED: 200, DELAY: "fast", "removed_knob": 3})

	assert_eq(tuning.value(SPEED), 200.0)
	assert_eq(tuning.value(DELAY), 0.3)


func test_editing_a_copy_leaves_the_original_untouched() -> void:
	var original := _tuning()
	var copy := original.copy()

	copy.set_value(SPEED, 250.0)

	assert_eq(original.value(SPEED), 150.0)


func test_export_is_json_with_every_value_and_what_changed() -> void:
	var tuning := _tuning()
	tuning.set_value(DELAY, 0.5)

	var exported: Dictionary = JSON.parse_string(tuning.export_text())

	assert_eq(exported[Tuning.EXPORT_MARKER], float(Tuning.EXPORT_VERSION))
	assert_eq(exported["changed"], ["delay"])
	assert_eq(exported["values"], {"speed": 150.0, "delay": 0.5})
