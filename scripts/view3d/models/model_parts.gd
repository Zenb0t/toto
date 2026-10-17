class_name ModelParts
extends RefCounted
## Shared helpers for the placeholder models: plain meshes with flat colours.


static func part(mesh: Mesh, color: Color, at := Vector3.ZERO, glowing := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material(color, glowing)
	return instance


## Glowing parts ignore the light, so they read as bright as their colour.
static func material(color: Color, glowing := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	if glowing:
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return result


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh


static func capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 4
	return mesh


## A flat bar (like a health bar) that always faces the camera and draws over the scene. It starts at its
## left end (at), so scaling it along x empties it from the right. draw_order: higher draws on top.
static func bar(size: Vector2, color: Color, draw_order: int, at: Vector3) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	quad.center_offset = Vector3(size.x / 2.0, 0, 0)
	var bar_material := material(color, true)
	bar_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bar_material.billboard_keep_scale = true
	bar_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bar_material.no_depth_test = true
	bar_material.render_priority = draw_order
	quad.material = bar_material
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.position = at
	return instance
