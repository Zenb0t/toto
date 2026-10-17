class_name PotionDrop
extends PickupArea
## A potion lying on the floor. Unlike gear there is nothing to choose: walking over it picks it up, if the
## belt has room (that is decided elsewhere).
## On the 2D plane (the floor) it draws a glow in the potion's colour; the 3D view draws the flask.

const PICKUP_RADIUS := 14.0
const GLOW_ALPHA := 0.3

var potion: Potion


func _init(dropped: Potion) -> void:
	super(PICKUP_RADIUS)
	potion = dropped


func _draw() -> void:
	draw_circle(Vector2.ZERO, PICKUP_RADIUS, Color(potion.color, GLOW_ALPHA))
