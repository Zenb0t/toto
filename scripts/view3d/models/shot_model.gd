class_name ShotModel
extends Node3D
## Placeholder projectile: a glowing ball flying at hand height, or as high as a lob has risen.

## Shots leave the hand at about the height of the weapon.
const HAND_HEIGHT := 0.45

var _ball: MeshInstance3D


func _init(color: Color, radius_pixels: float) -> void:
	_ball = ModelParts.part(ModelParts.sphere(WorldSpace.length_to_3d(radius_pixels)), color, Vector3.ZERO, true)
	add_child(_ball)
	lift(0.0)


## height_pixels: how high a lob is above its shadow on the 2D plane.
func lift(height_pixels: float) -> void:
	_ball.position.y = HAND_HEIGHT + WorldSpace.length_to_3d(height_pixels)
