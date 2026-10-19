class_name DecorModel
extends RefCounted
## The small things lying about a branch (see BranchLook.clutter): KayKit's dungeon props where the pack has
## them (candles, bottles, coins), and simple shapes for the rest: glowing mushrooms and grass in the Lair,
## boulders in the caves, coffins and bones in the Crypt, braziers in the Depths. Only looks.

const MUSHROOM_STEM_COLOR := Color(0.9, 0.88, 0.8)
const MUSHROOM_CAP_COLORS: Array[Color] = [Color(0.35, 0.95, 0.85), Color(0.75, 0.45, 1.0), Color(0.95, 0.4, 0.35)]
const GRASS_COLOR := Color(0.35, 0.6, 0.25)
const BOULDER_COLOR := Color(0.45, 0.42, 0.38)
const COFFIN_COLOR := Color(0.3, 0.2, 0.15)
const COFFIN_LID_COLOR := Color(0.42, 0.3, 0.22)
const BONE_COLOR := Color(0.92, 0.9, 0.82)
const BRAZIER_COLOR := Color(0.25, 0.22, 0.2)
const EMBER_COLOR := Color(1.0, 0.55, 0.2)


## A decoration of a kind; variant (0..1) picks among looks of the same kind, so no two are alike.
static func make(kind: String, variant: float) -> Node3D:
	match kind:
		"mushrooms":
			return _mushrooms(variant)
		"grass":
			return _grass(variant)
		"boulder":
			return _boulder(variant)
		"coffin":
			return _coffin()
		"bones":
			return _bones(variant)
		"brazier":
			return _brazier()
		"tree":
			return _tree(variant)
	return PropModel.make(kind)


static func _mushrooms(variant: float) -> Node3D:
	var patch := Node3D.new()
	var cap_color := MUSHROOM_CAP_COLORS[floori(variant * MUSHROOM_CAP_COLORS.size()) % MUSHROOM_CAP_COLORS.size()]
	for i in 3:
		var at := Vector3(cos(i * 2.1 + variant * 6.0), 0, sin(i * 2.1 + variant * 6.0)) * 0.16
		var height := 0.12 + 0.08 * i
		var stem := CylinderMesh.new()
		stem.top_radius = 0.03
		stem.bottom_radius = 0.04
		stem.height = height
		patch.add_child(ModelParts.part(stem, MUSHROOM_STEM_COLOR, at + Vector3(0, height / 2.0, 0)))
		var cap := ModelParts.part(ModelParts.sphere(0.08 + 0.02 * i), cap_color, at + Vector3(0, height, 0), true)
		cap.scale = Vector3(1, 0.55, 1)
		patch.add_child(cap)
	return patch


static func _grass(variant: float) -> Node3D:
	var tuft := Node3D.new()
	for i in 6:
		var blade := ModelParts.part(ModelParts.box(Vector3(0.03, 0.22, 0.03)), GRASS_COLOR.lightened(0.1 * (i % 3)),
			Vector3((i % 3 - 1) * 0.08, 0.1, (i / 3 - 0.5) * 0.1))
		blade.rotation = Vector3((variant - 0.5) * 0.6 + i * 0.2, 0, (i - 2.5) * 0.18)
		tuft.add_child(blade)
	return tuft


static func _boulder(variant: float) -> Node3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.26
	mesh.height = 0.4
	mesh.radial_segments = 7
	mesh.rings = 3
	var rock := ModelParts.part(mesh, BOULDER_COLOR.darkened(variant * 0.25), Vector3(0, 0.12, 0))
	rock.scale = Vector3(1.0 + variant * 0.4, 1.0, 0.8)
	var holder := Node3D.new()
	holder.add_child(rock)
	return holder


static func _coffin() -> Node3D:
	var coffin := Node3D.new()
	coffin.add_child(ModelParts.part(ModelParts.box(Vector3(0.36, 0.16, 0.78)), COFFIN_COLOR, Vector3(0, 0.08, 0)))
	coffin.add_child(ModelParts.part(ModelParts.box(Vector3(0.4, 0.05, 0.82)), COFFIN_LID_COLOR, Vector3(0, 0.18, 0)))
	coffin.add_child(ModelParts.part(ModelParts.box(Vector3(0.05, 0.02, 0.3)), BONE_COLOR, Vector3(0, 0.215, -0.1)))
	coffin.add_child(ModelParts.part(ModelParts.box(Vector3(0.18, 0.02, 0.05)), BONE_COLOR, Vector3(0, 0.215, -0.16)))
	return coffin


static func _bones(variant: float) -> Node3D:
	var pile := Node3D.new()
	for i in 4:
		var bone := ModelParts.part(ModelParts.box(Vector3(0.04, 0.04, 0.26)), BONE_COLOR,
			Vector3((i - 1.5) * 0.06, 0.03, 0))
		bone.rotation.y = i * 0.9 + variant * 3.0
		pile.add_child(bone)
	pile.add_child(ModelParts.part(ModelParts.sphere(0.08), BONE_COLOR, Vector3(0.12, 0.07, 0.1)))
	return pile


static func _brazier() -> Node3D:
	var brazier := Node3D.new()
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.2
	bowl.bottom_radius = 0.1
	bowl.height = 0.14
	brazier.add_child(ModelParts.part(ModelParts.box(Vector3(0.06, 0.4, 0.06)), BRAZIER_COLOR, Vector3(0, 0.2, 0)))
	brazier.add_child(ModelParts.part(bowl, BRAZIER_COLOR, Vector3(0, 0.44, 0)))
	var embers := ModelParts.part(ModelParts.sphere(0.13), EMBER_COLOR, Vector3(0, 0.52, 0), true)
	embers.scale = Vector3(1, 0.6, 1)
	brazier.add_child(embers)
	return brazier


## A tree as tall as a wall (see TreeShape).
static func _tree(variant: float) -> Node3D:
	var tree := Node3D.new()
	var trunk := CylinderMesh.new()
	trunk.top_radius = TreeShape.TRUNK_TOP_RADIUS
	trunk.bottom_radius = TreeShape.TRUNK_BOTTOM_RADIUS
	trunk.height = TreeShape.TRUNK_HEIGHT
	tree.add_child(ModelParts.part(trunk, TreeShape.TRUNK_COLOR, Vector3(0, TreeShape.TRUNK_HEIGHT / 2.0, 0)))
	for ball in TreeShape.crown(variant):
		tree.add_child(ModelParts.part(ModelParts.sphere(ball.radius), ball.color, ball.center))
	return tree
