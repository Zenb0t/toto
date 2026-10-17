class_name Bow
extends Weapon
## Angelo's bow from Brawl Stars: one fast arrow along a long, narrow line, and the longer the button is held
## before letting go the harder it hits (see Charge). A tap is a weak arrow; a full charge hits hardest and
## pierces, passing through every enemy on the line. The hero walks slower while drawing the bow.
## Enemies don't charge: whatever they hold shoots fully charged.

var min_damage := 60
var max_damage := 240
## Seconds of holding for a full charge.
var full_charge_seconds := 1.5
var shot_speed := 900.0
var shot_range := 460.0
## Share of the hero's speed while the bow is being drawn.
var charging_speed_share := 0.5


func _init() -> void:
	id = "bow"
	display_name = "Bow"
	description = "Hold to draw: a full charge hits hardest and pierces."
	button_label = "BOW"
	color = Color(0.95, 0.75, 0.35)
	reload = 1.5
	windup = 0.05


func knobs() -> Array[Knob]:
	var result := super.knobs()
	result.append_array([
		Knob.new("min_damage", "Damage, tap", 10, 500, 10, true),
		Knob.new("max_damage", "Damage, full charge", 10, 800, 10, true),
		Knob.new("full_charge_seconds", "Full charge (s)", 0.2, 4.0, 0.1),
		Knob.new("shot_speed", "Arrow speed", 200, 1800, 10),
		Knob.new("shot_range", "Range", 100, 1200, 10),
		Knob.new("charging_speed_share", "Speed while drawing", 0.1, 1.0, 0.05),
	])
	return result


func charge_seconds() -> float:
	return full_charge_seconds


func charging_move_share() -> float:
	return charging_speed_share


## Fully charged: how enemies shoot.
func attacks(origin: Vector2, direction: Vector2, aim_distance: float) -> Array:
	return charged_attacks(origin, direction, aim_distance, Charge.FULL)


func charged_attacks(origin: Vector2, direction: Vector2, _aim_distance: float, held_seconds: float) -> Array:
	var arrow_damage := Charge.damage(held_seconds, full_charge_seconds, min_damage, max_damage)
	var arrow := Shot.new(Weapon.muzzle(origin, direction), direction, shot_speed, arrow_damage, shot_range)
	arrow.pierces = Charge.is_full(held_seconds, full_charge_seconds)
	arrow.size = 3.0
	arrow.color = color
	return [arrow]


func travel_seconds(distance: float) -> float:
	return distance / shot_speed


func aim_range() -> float:
	return shot_range


func aim_shape() -> AimShape:
	return AimShape.line(shot_range)
