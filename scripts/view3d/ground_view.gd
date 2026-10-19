class_name GroundView
extends Node3D
## Lays the 2D game plane on the floor of the 3D view. Everything the 2D world draws (the map's floor,
## aim previews, telegraphs, slashes, blasts, the fog) is rendered into a texture around the camera, and
## that texture covers a flat quad on the floor. The 3D view adds only what stands up.

## The canvas layer the 2D plane is drawn on: the floor texture renders it, the screen doesn't.
const PLANE_LAYER := 1 << 19
## How much of the plane the texture covers, in cells. Enough to fill the screen at the camera's default
## framing on a wide phone; beyond it is the same dark as the unexplored map.
const WINDOW_CELLS := Vector2i(44, 26)
## Texture pixels per 2D pixel, so the floor stays sharp when the camera is close.
const TEXELS_PER_PIXEL := 1.5

var _window := GroundWindow.new(_texture_size(), TEXELS_PER_PIXEL)
var _texture_view := SubViewport.new()
var _floor := MeshInstance3D.new()
var _quad := PlaneMesh.new()


func _ready() -> void:
	_texture_view.size = _window.size
	_texture_view.disable_3d = true
	_texture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_texture_view)
	_texture_view.world_2d = get_viewport().world_2d

	_fit_quad()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _texture_view.get_texture()
	_quad.material = material
	_floor.mesh = _quad
	add_child(_floor)


## How far the floor reaches compared with the default framing (2 = twice as many cells each way; never less than
## 1). The texture keeps its size, so a farther camera sees a coarser floor rather than a bigger texture.
func set_reach(share: float) -> void:
	var stretch := maxf(share, 1.0)
	var center := _window.area().get_center()
	_window = GroundWindow.new(_texture_size(), TEXELS_PER_PIXEL / stretch)
	_window.center_on(center)
	_fit_quad()


## How many cells the floor covers now.
func reach_cells() -> Vector2:
	return _window.area().size / DungeonView.TILE_SIZE


func _fit_quad() -> void:
	var area := _window.area()
	_quad.size = Vector2(WorldSpace.length_to_3d(area.size.x), WorldSpace.length_to_3d(area.size.y))


static func _texture_size() -> Vector2i:
	return Vector2i(Vector2(WINDOW_CELLS * DungeonView.TILE_SIZE) * TEXELS_PER_PIXEL)


## Draws plane (and everything under it) on the floor only, instead of flat on the screen.
func lay_down(plane: CanvasItem) -> void:
	plane.visibility_layer = PLANE_LAYER
	get_viewport().canvas_cull_mask &= ~PLANE_LAYER


## Centres the floor texture on a point of the 2D plane.
func show_around(point: Vector2) -> void:
	_window.center_on(point)
	_texture_view.canvas_transform = _window.canvas_transform()
	_floor.position = WorldSpace.to_3d(_window.area().get_center())
