class_name Chest
extends PickupArea
## Appears when a room is cleared. Walking onto it opens it (once); what comes out is up to whoever listens.
## A chest opened on an earlier visit to its map comes back already open, and empty.
## An open chest stays on the floor, so the player can see which rooms they have already looted.
## A chest can be locked (a trap room's, until its band is dead): it stays shut and ignores the hero until unlocked.
## On the 2D plane (the floor) it draws only its shadow; the 3D view draws the chest.

signal opened

const SIZE := Vector2(26, 20)
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
const SHADOW_GROWTH := 3.0

var _open := false
var _locked := false


func _init(already_open := false, locked := false) -> void:
	super(SIZE.x / 2.0)
	_open = already_open
	_locked = locked and not already_open
	player_entered.connect(_on_player_entered)


func is_open() -> bool:
	return _open


func is_locked() -> bool:
	return _locked


## The chest opens to the hero from now on, at once if the hero is standing on it.
func unlock() -> void:
	_locked = false
	if is_inside_tree() and get_overlapping_bodies().any(func(body: Node2D) -> bool: return body is Player):
		_on_player_entered()


func _on_player_entered() -> void:
	if _open or _locked:
		return
	_open = true
	opened.emit()


func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2.0, SIZE).grow(SHADOW_GROWTH), SHADOW_COLOR)
