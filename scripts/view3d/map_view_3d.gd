class_name MapView3D
extends Node3D
## The map's walls, and the doors of locked rooms, as blocks standing on the floor. Like the fog on the
## floor, blocks the player has never seen aren't shown, and those out of sight are dimmed.
## Owns no game rules: it is told which cells are walls and doors, which doors are closed and what is seen.

const DEFAULT_WALL_HEIGHT := 1.0
const WALL_COLOR := Color(0.5, 0.47, 0.55)
const DOOR_COLOR := Color(0.8, 0.5, 0.25)
## Brightness of a block the player remembers but can't see right now.
const REMEMBERED_BRIGHTNESS := 0.35
const HIDDEN := 0.0
const LIT := 1.0

## Height of the walls, in cells. Closed doors are as tall.
var wall_height := DEFAULT_WALL_HEIGHT:
	set(value):
		wall_height = value
		_refresh()

var _cells: Array[Vector2i] = []  ## Walls first, then doors: the block for _cells[i] is instance i.
var _has_block := {}  # Vector2i -> true
var _door_cells := {}  # Vector2i -> true
var _closed_doors := {}  # Vector2i -> true
var _exploration: Exploration
var _blocks := MultiMesh.new()


func _init() -> void:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	var box := BoxMesh.new()
	box.material = material
	_blocks.transform_format = MultiMesh.TRANSFORM_3D
	_blocks.use_colors = true
	_blocks.mesh = box
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _blocks
	add_child(instance)


func show_map(wall_cells: Array[Vector2i], door_cells: Array[Vector2i]) -> void:
	_cells = wall_cells.duplicate()
	_cells.append_array(door_cells)
	_has_block.clear()
	for cell in _cells:
		_has_block[cell] = true
	_door_cells.clear()
	for cell in door_cells:
		_door_cells[cell] = true
	_closed_doors.clear()
	_blocks.instance_count = _cells.size()
	_refresh()


func set_doors_closed(door_cells: Array[Vector2i], closed: bool) -> void:
	for cell in door_cells:
		if closed:
			_closed_doors[cell] = true
		else:
			_closed_doors.erase(cell)
	_refresh()


func show_exploration(exploration: Exploration) -> void:
	_exploration = exploration
	_refresh()


## Whether a block stands on this cell and can be seen: a wall the player knows of, or a closed door.
func is_standing(cell: Vector2i) -> bool:
	return brightness(cell) > HIDDEN


## How brightly a cell's block shows: HIDDEN, REMEMBERED_BRIGHTNESS or LIT.
func brightness(cell: Vector2i) -> float:
	if not _has_block.has(cell) or (_door_cells.has(cell) and not _closed_doors.has(cell)):
		return HIDDEN
	if _exploration == null:
		return LIT
	if not _exploration.is_seen(cell):
		return HIDDEN
	return LIT if _exploration.is_visible(cell) else REMEMBERED_BRIGHTNESS


func _refresh() -> void:
	for i in _cells.size():
		var cell := _cells[i]
		var shade := brightness(cell)
		# A hidden block shrinks to nothing; a flattened one would still darken the floor.
		var size := Vector3(1.0, wall_height, 1.0) if shade > HIDDEN else Vector3.ZERO
		var basis := Basis.from_scale(size)
		var center := WorldSpace.to_3d(DungeonView.cell_center(cell), size.y / 2.0)
		_blocks.set_instance_transform(i, Transform3D(basis, center))
		var color := DOOR_COLOR if _door_cells.has(cell) else WALL_COLOR
		_blocks.set_instance_color(i, Color(color * shade, 1.0))
