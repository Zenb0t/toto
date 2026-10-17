class_name Chest
extends PickupArea
## Appears when a room is cleared. Walking onto it opens it (once); what comes out is up to whoever listens.
## An open chest stays on the floor, so the player can see which rooms they have already looted.
## On the 2D plane (the floor) it draws only its shadow; the 3D view draws the chest.

signal opened

const SIZE := Vector2(26, 20)
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
const SHADOW_GROWTH := 3.0

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
	opened.emit()


func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2.0, SIZE).grow(SHADOW_GROWTH), SHADOW_COLOR)
