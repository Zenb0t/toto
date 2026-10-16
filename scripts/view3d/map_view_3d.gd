class_name MapView3D
extends Node3D
## What stands on the floor: the walls (stone, with a lighter cap that overhangs a little, like Brawl Stars'
## blocks), pillars as round columns, the doors of locked rooms, torches on the walls and the arch over the
## stairs. Like the fog on
## the floor, what the player has never seen isn't shown, and what is out of sight is dimmed.
## Owns no game rules: it is told the map, which doors are closed and what is seen.

const DEFAULT_WALL_HEIGHT := 1.0
const WALL_COLOR := Color(0.42, 0.39, 0.47)
const CAP_COLOR := Color(0.64, 0.6, 0.7)
const CAP_THICKNESS := 0.16
const CAP_OVERHANG := 0.05
const DOOR_COLOR := Color(0.55, 0.35, 0.2)
const DOOR_CAP_COLOR := Color(0.78, 0.52, 0.28)
const COLUMN_RADIUS := 0.36
## How much each stone block's colour varies, so walls don't look flat.
const STONE_TINT := 0.06
## Brightness of a block the player remembers but can't see right now.
const REMEMBERED_BRIGHTNESS := 0.35
const HIDDEN := 0.0
const LIT := 1.0

## Height of the walls, in cells. Closed doors are as tall.
var wall_height := DEFAULT_WALL_HEIGHT:
	set(value):
		wall_height = value
		_refresh(true)

## Walls (not pillars) and doors: the body and cap of _block_cells[i] are instance i of each.
var _block_cells: Array[Vector2i] = []
## Pillars: column j is instance j of _columns, and its cap is instance _block_cells.size() + j of _caps.
var _column_cells: Array[Vector2i] = []
var _has_block := {}  # Vector2i -> true, for walls, pillars and doors
var _door_cells := {}  # Vector2i -> true
var _closed_doors := {}  # Vector2i -> true
var _torches := {}  # wall cell -> TorchModel
var _shown := {}  # Vector2i -> the brightness last shown, so a refresh only touches what changed
var _exploration: Exploration
var _stairs_cell := DungeonMap.NO_CELL
var _stairs := StairsModel.new()
var _blocks := _multimesh(ModelParts.box(Vector3.ONE))
var _caps := _multimesh(ModelParts.box(Vector3.ONE))
var _columns := _multimesh(_column_mesh())


func _init() -> void:
	for multimesh in [_blocks, _caps, _columns]:
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		add_child(instance)
	add_child(_stairs)


## wall_cells: the walls to stand up (those next to open cells).
func show_map(map: DungeonMap, wall_cells: Array[Vector2i]) -> void:
	var pillars := DungeonDecor.pillar_cells(map, wall_cells)
	_column_cells = pillars
	_block_cells.clear()
	for cell in wall_cells:
		if cell not in pillars:
			_block_cells.append(cell)
	_block_cells.append_array(map.door_cells())
	_has_block.clear()
	for cell in wall_cells + map.door_cells():
		_has_block[cell] = true
	_door_cells.clear()
	for cell in map.door_cells():
		_door_cells[cell] = true
	_closed_doors.clear()
	_blocks.instance_count = _block_cells.size()
	_caps.instance_count = _block_cells.size() + _column_cells.size()
	_columns.instance_count = _column_cells.size()
	for torch: Node in _torches.values():
		torch.queue_free()
	_torches.clear()
	_stairs_cell = map.exit_cell
	for cell in DungeonDecor.torch_cells(map, wall_cells):
		var torch := TorchModel.new()
		add_child(torch)
		_torches[cell] = torch
	_refresh(true)


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


## How brightly a cell's block (or torch) shows: HIDDEN, REMEMBERED_BRIGHTNESS or LIT.
func brightness(cell: Vector2i) -> float:
	if not _has_block.has(cell) or (_door_cells.has(cell) and not _closed_doors.has(cell)):
		return HIDDEN
	if _exploration == null:
		return LIT
	if not _is_known(cell, _exploration.is_seen):
		return HIDDEN
	return LIT if _is_known(cell, _exploration.is_visible) else REMEMBERED_BRIGHTNESS


## Sight is worked out cell by cell, and a line along a wall grazes the wall cells beside it, so a wall
## counts as in sight (or seen) when it is, or when an open cell next to it is.
func _is_known(cell: Vector2i, known: Callable) -> bool:
	if known.call(cell):
		return true
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not _has_block.has(cell + step) and known.call(cell + step):
			return true
	return false


## Like brightness(), for something standing on open floor.
func _ground_brightness(cell: Vector2i) -> float:
	if cell == DungeonMap.NO_CELL:
		return HIDDEN
	if _exploration == null or _exploration.is_visible(cell):
		return LIT
	return REMEMBERED_BRIGHTNESS if _exploration.is_seen(cell) else HIDDEN


func torch_count() -> int:
	return _torches.size()


## Updates the blocks whose brightness changed (all of them when everything must be placed again).
func _refresh(everything := false) -> void:
	if everything:
		_shown.clear()
	for i in _block_cells.size():
		var cell := _block_cells[i]
		var shade := brightness(cell)
		if _shown.get(cell, -1.0) == shade:
			continue
		_shown[cell] = shade
		var is_door := _door_cells.has(cell)
		_place_block(i, cell, shade, DOOR_COLOR if is_door else WALL_COLOR)
		_place_cap(i, cell, shade, DOOR_CAP_COLOR if is_door else CAP_COLOR, 1.0 + CAP_OVERHANG * 2.0)
	for j in _column_cells.size():
		var cell := _column_cells[j]
		var shade := brightness(cell)
		if _shown.get(cell, -1.0) == shade:
			continue
		_shown[cell] = shade
		_place_column(j, cell, shade)
		_place_cap(_block_cells.size() + j, cell, shade, CAP_COLOR, COLUMN_RADIUS * 2.4)
	for cell: Vector2i in _torches:
		_torches[cell].show_on_wall(cell, wall_height, brightness(cell))
	_stairs.show_at(_stairs_cell, _ground_brightness(_stairs_cell))


## The wall's body, below its cap.
func _place_block(index: int, cell: Vector2i, shade: float, color: Color) -> void:
	var height := wall_height - CAP_THICKNESS
	_blocks.set_instance_transform(index, _upright(cell, Vector3(1.0, height, 1.0), height / 2.0, shade))
	_blocks.set_instance_color(index, _stone(color, cell, shade))


func _place_cap(index: int, cell: Vector2i, shade: float, color: Color, width: float) -> void:
	var size := Vector3(width, CAP_THICKNESS, width)
	_caps.set_instance_transform(index, _upright(cell, size, wall_height - CAP_THICKNESS / 2.0, shade))
	_caps.set_instance_color(index, _stone(color, cell, shade))


func _place_column(index: int, cell: Vector2i, shade: float) -> void:
	var height := wall_height - CAP_THICKNESS
	_columns.set_instance_transform(index, _upright(cell, Vector3(1.0, height, 1.0), height / 2.0, shade))
	_columns.set_instance_color(index, _stone(WALL_COLOR, cell, shade))


## A hidden piece shrinks to nothing; a flattened one would still darken the floor.
func _upright(cell: Vector2i, size: Vector3, center_height: float, shade: float) -> Transform3D:
	var shown_size := size if shade > HIDDEN else Vector3.ZERO
	return Transform3D(Basis.from_scale(shown_size), WorldSpace.to_3d(DungeonView.cell_center(cell), center_height))


func _stone(color: Color, cell: Vector2i, shade: float) -> Color:
	var tint := DungeonDecor.tint(cell) * STONE_TINT
	return Color((color.r + tint) * shade, (color.g + tint) * shade, (color.b + tint) * shade)


static func _multimesh(mesh: PrimitiveMesh) -> MultiMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	return multimesh


## A unit-tall column; each instance is scaled to the wall height.
static func _column_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = COLUMN_RADIUS
	mesh.bottom_radius = COLUMN_RADIUS * 1.1
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 1
	return mesh
