class_name ItemDrop
extends PickupArea
## An item (weapon or utility) lying on the floor, waiting for the player to take it or leave it.
## It holds the item only to show and identify it; taking it is decided elsewhere.
## On the 2D plane (the floor) it draws a glow in the item's colour; the 3D view draws the item and its name.

const PICKUP_RADIUS := 18.0
const GLOW_ALPHA := 0.25
const RIM_WIDTH := 2.0

var item: Item:
	set(value):
		item = value
		queue_redraw()


func _init(dropped: Item) -> void:
	super(PICKUP_RADIUS)
	item = dropped


func _draw() -> void:
	draw_circle(Vector2.ZERO, PICKUP_RADIUS, Color(item.color, GLOW_ALPHA))
	draw_arc(Vector2.ZERO, PICKUP_RADIUS, 0.0, TAU, 32, item.color, RIM_WIDTH, true)
