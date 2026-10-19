class_name Blink
extends Utility
## Like Dungeon Crawl's scroll of blinking: an instant hop to a spot you pick. How far the aim is dragged picks how
## far it goes, up to its range (a tap hops the whole way). It crosses whatever you can see across (water, lava,
## boulders) and passes enemies, but never a wall or a closed door, and lands only where you can stand (see
## BlinkLanding).

var distance := 140.0


func _init() -> void:
	id = "blink"
	display_name = "Blink"
	description = "Jump instantly to a spot you pick, over water and past enemies."
	button_label = "BLINK"
	color = Color(0.85, 0.5, 1.0)
	cooldown = 4.0
	slot = Slot.MOVEMENT


func knobs() -> Array[Knob]:
	var result: Array[Knob] = [Knob.new("distance", "Distance", 40, 400, 10)]
	result.append_array(super.knobs())
	return result


func activate(direction: Vector2, strength := 1.0) -> UtilityEffect:
	return UtilityEffect.blink(direction.normalized() * aim_distance(strength))


func aim_range() -> float:
	return distance


func hops() -> bool:
	return true


## The line to where the hero would land, and the hero's footprint there.
func aim_shape() -> AimShape:
	return AimShape.lob(distance, Player.RADIUS)
