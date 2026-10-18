class_name StairsModel
extends Node3D
## A stone arch over the stairs, trimmed in gold over the stairs down and in silver over the stairs up, so the
## way on (and back) reads from across the room.

const STONE_COLOR := Color(0.5, 0.46, 0.55)
const GOLD_COLOR := Color(0.95, 0.75, 0.3)
const SILVER_COLOR := Color(0.8, 0.84, 0.9)
const POST_SIZE := Vector3(0.18, 1.0, 0.18)
const SPAN := 0.82


func _init(trim_color := GOLD_COLOR) -> void:
	for side: float in [-1.0, 1.0]:
		add_child(ModelParts.part(ModelParts.box(POST_SIZE), STONE_COLOR,
			Vector3(side * SPAN / 2.0, POST_SIZE.y / 2.0, -0.35)))
	add_child(ModelParts.part(ModelParts.box(Vector3(SPAN + POST_SIZE.x, 0.16, 0.24)), STONE_COLOR,
		Vector3(0, POST_SIZE.y + 0.08, -0.35)))
	add_child(ModelParts.part(ModelParts.box(Vector3(SPAN + POST_SIZE.x + 0.04, 0.05, 0.26)), trim_color,
		Vector3(0, POST_SIZE.y + 0.18, -0.35), true))


## Stands on a cell; shows once seen, dimmed out of sight (see MapView3D).
func show_at(cell: Vector2i, brightness: float) -> void:
	position = WorldSpace.to_3d(DungeonView.cell_center(cell))
	visible = brightness > MapView3D.HIDDEN
