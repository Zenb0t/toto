class_name ForestView
extends Node3D
## Outdoors, the tree groves drawn as trees (see TreeShape), each a little bigger or smaller, nudged off the middle
## of its cell and turned, so woods look grown rather than laid out. Trees are big enough that their crowns meet in
## a canopy, so deep inside a wood only every other cell needs one (see tree_cells). They are drawn in square
## chunks of the map, each two MultiMeshes (trunks, balls of leaves), so only the chunks near the camera cost
## anything. Like the walls, a tree is hidden until seen, dimmed when out of sight, and shrunk when it stands
## between the camera and the hero. Owns no game rules: MapView3D says how each tree shows.

## A tree is this many times TreeShape's size (as tall as a wall), at least and at most: bigger than a cell, so
## the crowns of neighbouring trees meet in a canopy.
const SIZE_MIN := 1.5
const SIZE_MAX := 2.0
## How far a tree may stand off the middle of its cell, in cells.
const NUDGE := 0.2
## A tree in front of the hero shrinks to this share of its size, so it doesn't hide them.
const CUT_SIZE := 0.45
## Grove cells this close to open ground (counted the way a king moves) all get a tree; deeper in, every other one.
const EDGE_DEPTH := 2
## The trees of a square this many cells wide are drawn together.
const CHUNK_CELLS := 16
const HIDDEN := 0.0

## The trees of one chunk.
class Chunk:
	extends RefCounted
	var cells: Array[Vector2i] = []
	var trunks: MultiMesh
	var leaves: MultiMesh

var _chunks := {}  # Vector2i (chunk) -> Chunk
var _slot := {}  # Vector2i (cell) -> its index in its chunk's cells
var _shown := {}  # Vector2i -> Vector2(the brightness last shown, 1 if it was cut down)
var _trunk_mesh := _with_material(_trunk_shape())
var _leaf_mesh := _with_material(_leaf_shape())


## The grove cells that get a tree: every one near open ground, every other one deeper in.
static func tree_cells(map: DungeonMap) -> Array[Vector2i]:
	var groves := {}
	for cell in map.cells_with_blocker(DungeonMap.Blocker.GROVE):
		groves[cell] = true
	var depth := _depth_into(groves, EDGE_DEPTH)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in groves:
		if depth.has(cell) or (cell.x + cell.y) % 2 == 0:
			cells.append(cell)
	return cells


## Stands a tree on each of these cells (and takes away any trees from before), all hidden until shown.
func plant(cells: Array[Vector2i]) -> void:
	for child in get_children():
		child.queue_free()
	_chunks.clear()
	_slot.clear()
	_shown.clear()
	for cell in cells:
		var key := _chunk_of(cell)
		if not _chunks.has(key):
			_chunks[key] = Chunk.new()
		var chunk: Chunk = _chunks[key]
		_slot[cell] = chunk.cells.size()
		chunk.cells.append(cell)
	for chunk: Chunk in _chunks.values():
		chunk.trunks = _multimesh(_trunk_mesh, chunk.cells.size())
		chunk.leaves = _multimesh(_leaf_mesh, chunk.cells.size() * TreeShape.CROWN_BALLS)
		for multimesh in [chunk.trunks, chunk.leaves]:
			var instance := MultiMeshInstance3D.new()
			instance.multimesh = multimesh
			add_child(instance)
		for cell in chunk.cells:
			show_tree(cell, HIDDEN, false)


func has_tree(cell: Vector2i) -> bool:
	return _slot.has(cell)


func cells() -> Array[Vector2i]:
	var all: Array[Vector2i] = []
	all.assign(_slot.keys())
	return all


func tree_count() -> int:
	return _slot.size()


## How brightly the tree on a cell shows: HIDDEN, or the light on it (dimmed when remembered); cut: it stands in
## front of the hero.
func show_tree(cell: Vector2i, brightness: float, cut: bool) -> void:
	if not _slot.has(cell):
		return
	var shown := Vector2(brightness, 1.0 if cut else 0.0)
	if _shown.get(cell) == shown:
		return
	_shown[cell] = shown
	var chunk: Chunk = _chunks[_chunk_of(cell)]
	var i: int = _slot[cell]
	var tree := placement(cell)
	if brightness <= HIDDEN:
		tree = tree.scaled_local(Vector3.ZERO)
	elif cut:
		tree = tree.scaled_local(Vector3.ONE * CUT_SIZE)
	var trunk_size := Vector3(
		TreeShape.TRUNK_BOTTOM_RADIUS * 2.0, TreeShape.TRUNK_HEIGHT, TreeShape.TRUNK_BOTTOM_RADIUS * 2.0)
	var trunk := Transform3D(Basis.from_scale(trunk_size), Vector3(0, TreeShape.TRUNK_HEIGHT / 2.0, 0))
	chunk.trunks.set_instance_transform(i, tree * trunk)
	chunk.trunks.set_instance_color(i, _shade(TreeShape.TRUNK_COLOR, brightness))
	var crown := TreeShape.crown(variant(cell))
	for b in crown.size():
		var ball := crown[b]
		var leaves := Transform3D(Basis.from_scale(Vector3.ONE * ball.radius), ball.center)
		chunk.leaves.set_instance_transform(i * TreeShape.CROWN_BALLS + b, tree * leaves)
		chunk.leaves.set_instance_color(i * TreeShape.CROWN_BALLS + b, _shade(ball.color, brightness))


## How brightly the tree on a cell is drawn right now (-1 where there is none).
func shown_brightness(cell: Vector2i) -> float:
	return _shown[cell].x if _shown.has(cell) else -1.0


## Where the tree on a cell stands, how big it is and which way it is turned: fixed by the cell, so the same map
## always grows the same woods.
static func placement(cell: Vector2i) -> Transform3D:
	var size := lerpf(SIZE_MIN, SIZE_MAX, DungeonDecor.noise(cell, 17))
	var nudge := Vector2(DungeonDecor.noise(cell, 18) - 0.5, DungeonDecor.noise(cell, 19) - 0.5) * 2.0 * NUDGE
	var turn := Basis(Vector3.UP, DungeonDecor.noise(cell, 20) * TAU)
	var foot := WorldSpace.to_3d(DungeonView.cell_center(cell) + nudge * DungeonView.TILE_SIZE)
	return Transform3D(turn.scaled(Vector3.ONE * size), foot)


## Which of TreeShape's looks the tree on a cell has.
static func variant(cell: Vector2i) -> float:
	return DungeonDecor.noise(cell, 16)


## For each cell of `cells` within `limit` cells of a cell not in it (counted the way a king moves), how far that is.
static func _depth_into(cells: Dictionary, limit: int) -> Dictionary:
	var depth := {}  # Vector2i -> int
	var frontier: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if _touches_outside(cell, cells):
			depth[cell] = 1
			frontier.append(cell)
	for ring in range(2, limit + 1):
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var next := cell + Vector2i(dx, dy)
					if cells.has(next) and not depth.has(next):
						depth[next] = ring
						next_frontier.append(next)
		frontier = next_frontier
	return depth


static func _touches_outside(cell: Vector2i, cells: Dictionary) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if not cells.has(cell + Vector2i(dx, dy)):
				return true
	return false


static func _chunk_of(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / CHUNK_CELLS), floori(float(cell.y) / CHUNK_CELLS))


static func _shade(color: Color, brightness: float) -> Color:
	return Color(color.r * brightness, color.g * brightness, color.b * brightness)


## A ball of leaves one unit in radius, with few faces: woods hold thousands of them.
static func _leaf_shape() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return mesh


## A trunk one unit tall and one unit across at its foot, narrowing like TreeShape's.
static func _trunk_shape() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = 0.5
	mesh.top_radius = 0.5 * TreeShape.TRUNK_TOP_RADIUS / TreeShape.TRUNK_BOTTOM_RADIUS
	mesh.height = 1.0
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh


static func _with_material(mesh: PrimitiveMesh) -> PrimitiveMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	return mesh


static func _multimesh(mesh: Mesh, count: int) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = count
	return multimesh
