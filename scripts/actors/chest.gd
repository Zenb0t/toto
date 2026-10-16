class_name Chest
extends PickupArea
## Appears when a room is cleared. Walking onto it opens it (once); what comes out is up to whoever listens.
## An open chest stays on the floor, so the player can see which rooms they have already looted.

signal opened

const SIZE := Vector2(26, 20)
const BOX_COLOR := Color(0.55, 0.35, 0.2)
const BAND_COLOR := Color(0.95, 0.75, 0.3)
const OPEN_INSIDE_COLOR := Color(0.12, 0.08, 0.06)

var _open := false


func _init() -> void:
	super(SIZE.x / 2.0)
	player_entered.connect(_on_player_entered)


func is_open() -> bool:
	return _open


func _on_player_entered() -> void:
	if _open:
		return
	_open = true
	queue_redraw()
	opened.emit()


func _draw() -> void:
	var box := Rect2(-SIZE / 2.0, SIZE)
	draw_rect(box, BOX_COLOR)
	if _open:
		draw_rect(box.grow(-4.0), OPEN_INSIDE_COLOR)
	else:
		draw_rect(Rect2(box.position + Vector2(0, SIZE.y * 0.35), Vector2(SIZE.x, 3)), BAND_COLOR)
	draw_rect(box, BAND_COLOR, false, 2.0)
