class_name Knuckles
extends Weapon
## Brass knuckles, swung like El Primo's fists in Brawl Stars: a quick flurry of short punches straight ahead.
## Each punch is a short, fast shot thrown a moment after the last, from wherever the puncher stands by then,
## so a flurry follows a charge in. Weak at range, brutal up close when every punch lands.

var punches := 4
var punch_range := 90.0
var punch_speed := 900.0
var damage := 50
## Punches land a little to either side of the aim, alternating.
var spread_degrees := 8.0
## Seconds between two punches of a flurry.
var punch_gap := 0.07


func _init() -> void:
	id = "knuckles"
	display_name = "Knuckles"
	description = "A flurry of punches. Get close and every one lands."
	button_label = "FISTS"
	color = Color(0.95, 0.75, 0.45)
	reload = 1.0
	windup = 0.05


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("punches", "Punches", 1, 8, 1),
		Knob.new("punch_range", "Reach", 30, 200, 5),
		Knob.new("punch_speed", "Punch speed", 200, 1500, 10),
		Knob.new("damage", "Damage per punch", 10, 500, 10, true),
		Knob.new("spread_degrees", "Spread (deg)", 0, 30, 1),
		Knob.new("punch_gap", "Between punches (s)", 0.0, 0.3, 0.01),
	])
	return result


func attacks(origin: Vector2, direction: Vector2, _aim_distance: float) -> Array:
	var flurry := []
	for index in punches:
		var side := -1.0 if index % 2 == 0 else 1.0
		var aim := direction.rotated(deg_to_rad(spread_degrees / 2.0 * side))
		var punch := Shot.new(Weapon.muzzle(origin, aim), aim, punch_speed, damage, punch_range)
		punch.delay = index * punch_gap
		punch.size = 7.0
		punch.color = color
		flurry.append(punch)
	return flurry


func aim_range() -> float:
	return punch_range + Weapon.MUZZLE_DISTANCE


## Brawlers rush in.
func ideal_distance() -> float:
	return aim_range() * 0.5


func aim_shape() -> AimShape:
	return AimShape.cone(aim_range(), spread_degrees)
