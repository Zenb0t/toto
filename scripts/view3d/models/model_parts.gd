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
