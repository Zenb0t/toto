class_name VillageView3D
extends Node3D
## The village's buildings, palisade, well and props, standing on the floor. Each is a piece: a model, the map cells
## it stands on and how tall it is. A piece shows as bright as the brightest of its cells (never seen: not at all),
## and one that stands between the camera and the hero turns see-through (dithered), the way walls are cut down.
## Owns no game rules: it is told the village, what is seen and where the hero is.

## How see-through a piece gets (0 solid, 1 invisible).
const SEE_THROUGH := 0.75
const PROP_HEIGHT := 0.4
const HIDDEN := 0.0


## One thing standing in the village.
class Piece:
	extends RefCounted
	var model: Node3D
	var cells: Array[Vector2i]
	## How tall it stands, in cells.
	var height: float
	var meshes: Array[MeshInstance3D]
	var see_through := false
	var shade := -1.0
	## Whether it can hide the hero (props are too low to).
	var hides_hero := true

	func _init(node: Node3D, covered: Array[Vector2i], tall: float) -> void:
		model = node
		cells = covered
		height = tall
		meshes = VillageModels.meshes_of(node)
		for mesh in meshes:
			var material := mesh.get_active_material(0)
			if material != null:
				mesh.material_override = material.duplicate()

var _pieces: Array[Piece] = []


## Stands the village's pieces up. scale: see BranchLook.building_scale.
func show_village(village: Village, scale: float) -> void:
	clear()
	if village == null:
		return
	for building in village.buildings:
		_add_building(building, scale)
	_add_palisade(village, scale)
	if village.well_cell != DungeonMap.NO_CELL:
		_add_well(village.well_cell, scale)


func clear() -> void:
	for piece in _pieces:
		piece.model.queue_free()
	_pieces.clear()


## Adds the barrels and crates standing on cells.
func show_props(cells: Array[Vector2i], scale: float) -> void:
	for cell in cells:
		var model_name := VillageModels.PROPS[floori(DungeonDecor.noise(cell, 18) * VillageModels.PROPS.size())]
		var model := VillageModels.load_model(model_name, scale * VillageModels.PROP_FIT)
		model.position = WorldSpace.to_3d(DungeonView.cell_center(cell))
		model.rotation.y = DungeonDecor.noise(cell, 19) * TAU
		add_child(model)
		var piece := Piece.new(model, [cell] as Array[Vector2i], PROP_HEIGHT)
		piece.hides_hero = false
		_pieces.append(piece)


func piece_count() -> int:
	return _pieces.size()


## Shows each piece as bright as the brightest of its cells; brightness: Callable(cell) -> float (0 hides).
func show_brightness(brightness: Callable) -> void:
	for piece in _pieces:
		var best := HIDDEN
		for cell in piece.cells:
			best = maxf(best, brightness.call(cell))
			if best >= 1.0:
				break
		if best == piece.shade:
			continue
		piece.shade = best
		piece.model.visible = best > HIDDEN
		for mesh in piece.meshes:
			if mesh.material_override is BaseMaterial3D:
				mesh.material_override.albedo_color = Color(best, best, best)


## Pieces between the camera and a hero standing on a cell turn see-through; the rest turn solid again.
func show_hero_at(hero_cell: Vector2i) -> void:
	for piece in _pieces:
		var hiding := piece.hides_hero and _covers_any(piece, CameraFraming.cells_hiding(hero_cell, piece.height))
		if hiding == piece.see_through:
			continue
		piece.see_through = hiding
		for mesh in piece.meshes:
			mesh.transparency = SEE_THROUGH if hiding else 0.0


## Whether the piece standing on a cell is see-through now (false where nothing of the village stands).
func is_see_through(cell: Vector2i) -> bool:
	for piece in _pieces:
		if cell in piece.cells:
			return piece.see_through
	return false


## Whether a piece of the village stands on a cell.
func has_piece_at(cell: Vector2i) -> bool:
	for piece in _pieces:
		if cell in piece.cells:
			return true
	return false


static func _covers_any(piece: Piece, hiding: Array[Vector2i]) -> bool:
	for cell in hiding:
		if cell in piece.cells:
			return true
	return false


func _add_building(building: Village.Building, scale: float) -> void:
	var model := VillageModels.load_model(VillageModels.building_name(building), scale)
	var pivot := _pivot_for(model, Vector2(building.rect.position) + Vector2(building.rect.size) / 2.0)
	# The pack's doors face +Z; the pivot turns them toward the street.
	pivot.rotation.y = WorldSpace.yaw_toward(-Vector2(building.facing))
	_pieces.append(Piece.new(pivot, _cells_of(building.rect), VillageModels.bounds_of(model).size.y))


func _add_well(well_cell: Vector2i, scale: float) -> void:
	var model := VillageModels.load_model(VillageModels.WELL, scale * VillageModels.WELL_FIT)
	var pivot := _pivot_for(model, Vector2(well_cell) + Vector2(0.5, 0.5))
	var cells := _cells_of(Rect2i(well_cell - Vector2i.ONE, Vector2i(3, 3)))
	_pieces.append(Piece.new(pivot, cells, VillageModels.bounds_of(model).size.y))


## A wooden fence along each side, an odd number of pieces so the middle one is the gate.
func _add_palisade(village: Village, scale: float) -> void:
	var area := village.area
	var piece_length := VillageModels.FENCE_LENGTH * scale
	for side in QuadrantExits.SIDES:
		var along := Vector2i(absi(side.y), absi(side.x))
		# The up and down sides run the full width; the left and right ones between the corners they share.
		var origin := Vector2i(area.position.x, area.position.y if side.y <= 0 else area.end.y - 1)
		var length := area.size.x
		if side.y == 0:
			origin = Vector2i(area.position.x if side.x < 0 else area.end.x - 1, area.position.y + 1)
			length = area.size.y - 2
		var count := _odd_count(length / piece_length)
		var step := float(length) / count
		for i in count:
			var cells: Array[Vector2i] = []
			for k in range(floori(i * step), maxi(floori((i + 1) * step), floori(i * step) + 1)):
				cells.append(origin + along * k)
			var model := VillageModels.load_model(VillageModels.GATE if i == count / 2 else VillageModels.FENCE, scale)
			# Stretched a little along its length so the pieces meet.
			model.scale.z = scale * step / piece_length
			var middle := Vector2(origin) + Vector2(0.5, 0.5) + Vector2(along) * ((i + 0.5) * step - 0.5)
			var pivot := _pivot_for(model, middle)
			# The pack's fence runs along Z; the sides that run along X turn a quarter.
			pivot.rotation.y = PI / 2.0 if side.y != 0 else 0.0
			_pieces.append(Piece.new(pivot, cells, VillageModels.bounds_of(model).size.y))


## A node on the floor at a point of the plane (cells), holding a model with the middle of its footprint on it.
func _pivot_for(model: Node3D, centre: Vector2) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = WorldSpace.to_3d(centre * DungeonView.TILE_SIZE)
	var bounds := VillageModels.bounds_of(model)
	model.position = -Vector3(bounds.position.x + bounds.size.x / 2.0, 0.0, bounds.position.z + bounds.size.z / 2.0)
	pivot.add_child(model)
	add_child(pivot)
	return pivot


static func _odd_count(pieces: float) -> int:
	var count := maxi(roundi(pieces), 1)
	return count if count % 2 == 1 else count + 1


static func _cells_of(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells
