class_name LichDress
extends RefCounted
## The Lich's costume: a Skeleton Mage dressed in code. A gold crown, glowing eyes, a long dark robe and a staff
## with a glowing orb, all built from plain shapes on the skeleton's bones (the model's own hat comes off). The
## model is scaled up by the monster's size and tinted dark purple (see CharacterLook).

const COSTUME := "lich"
const CROWN_GOLD := Color(0.95, 0.78, 0.25)
const ROBE_COLOR := Color(0.16, 0.07, 0.24)
const TRIM_COLOR := Color(0.5, 0.25, 0.7)
const EYE_COLOR := Color(0.55, 1.0, 0.45)
const STAFF_COLOR := Color(0.2, 0.12, 0.08)
const ORB_COLOR := Color(0.65, 0.4, 1.0)
const CROWN_SPIKES := 5


## Puts the costume on the skeleton's bones. Returns every mesh it added (they flash when he is hit).
static func put_on(skeleton: Skeleton3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	meshes.append_array(_crown(skeleton))
	meshes.append_array(_eyes(skeleton))
	meshes.append_array(_robe(skeleton))
	meshes.append_array(_staff(skeleton))
	return meshes


static func _attach(skeleton: Skeleton3D, bone: String) -> BoneAttachment3D:
	var slot := BoneAttachment3D.new()
	slot.bone_name = bone
	skeleton.add_child(slot)
	return slot


## A gold band with spikes round the top of the skull.
static func _crown(skeleton: Skeleton3D) -> Array[MeshInstance3D]:
	var slot := _attach(skeleton, "head")
	var meshes: Array[MeshInstance3D] = []
	var band_mesh := CylinderMesh.new()
	band_mesh.top_radius = 0.4
	band_mesh.bottom_radius = 0.42
	band_mesh.height = 0.16
	var band := ModelParts.part(band_mesh, CROWN_GOLD, Vector3(0, 0.92, 0), true)
	slot.add_child(band)
	meshes.append(band)
	for index in CROWN_SPIKES:
		var angle := TAU * index / CROWN_SPIKES
		var spike_mesh := CylinderMesh.new()
		spike_mesh.top_radius = 0.0
		spike_mesh.bottom_radius = 0.07
		spike_mesh.height = 0.26
		var spike := ModelParts.part(
			spike_mesh, CROWN_GOLD, Vector3(cos(angle) * 0.38, 1.1, sin(angle) * 0.38), true)
		slot.add_child(spike)
		meshes.append(spike)
	return meshes


## Two glowing points in the sockets.
static func _eyes(skeleton: Skeleton3D) -> Array[MeshInstance3D]:
	var slot := _attach(skeleton, "head")
	var meshes: Array[MeshInstance3D] = []
	for side in [-1.0, 1.0]:
		var eye := ModelParts.part(ModelParts.sphere(0.06), EYE_COLOR, Vector3(side * 0.12, 0.4, 0.3), true)
		slot.add_child(eye)
		meshes.append(eye)
	return meshes


## A long dark robe from the shoulders to the floor, with a purple hem.
static func _robe(skeleton: Skeleton3D) -> Array[MeshInstance3D]:
	var slot := _attach(skeleton, "hips")
	var robe_mesh := CylinderMesh.new()
	robe_mesh.top_radius = 0.34
	robe_mesh.bottom_radius = 0.62
	robe_mesh.height = 1.3
	var robe := ModelParts.part(robe_mesh, ROBE_COLOR, Vector3(0, 0.25, 0))
	slot.add_child(robe)
	var hem_mesh := CylinderMesh.new()
	hem_mesh.top_radius = 0.63
	hem_mesh.bottom_radius = 0.64
	hem_mesh.height = 0.1
	var hem := ModelParts.part(hem_mesh, TRIM_COLOR, Vector3(0, -0.35, 0))
	slot.add_child(hem)
	return [robe, hem]


## A tall staff in the left hand, topped with a glowing orb.
static func _staff(skeleton: Skeleton3D) -> Array[MeshInstance3D]:
	var slot := _attach(skeleton, "handslot.l")
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.03
	pole_mesh.bottom_radius = 0.04
	pole_mesh.height = 2.1
	var pole := ModelParts.part(pole_mesh, STAFF_COLOR, Vector3(0, 0.5, 0))
	slot.add_child(pole)
	var orb := ModelParts.part(ModelParts.sphere(0.13), ORB_COLOR, Vector3(0, 1.6, 0), true)
	slot.add_child(orb)
	return [pole, orb]
