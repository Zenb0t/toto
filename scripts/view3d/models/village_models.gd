class_name VillageModels
extends RefCounted
## The village's pieces from KayKit's Medieval Hexagon pack (CC0, by Kay Lousberg; see
## assets/kaykit_medieval_hexagon): houses in four colours, the inn (a red tavern), the church (blue), the smithy
## (green), the market (yellow), the well, the wooden fence as the palisade and its gate, and barrels and crates.
## The pack's pieces are tiny next to one of our cells, so they are drawn bigger (BranchLook.building_scale, 6 by
## default). Only looks.

const PATH := "res://assets/kaykit_medieval_hexagon/%s.gltf"
## The small house and the big one, each in the four colours (a house's colour is its variant).
const SMALL_HOUSES: Array[String] = [
	"building_home_A_blue", "building_home_A_red", "building_home_A_green", "building_home_A_yellow"]
const BIG_HOUSES: Array[String] = [
	"building_home_B_blue", "building_home_B_red", "building_home_B_green", "building_home_B_yellow"]
const INN := "building_tavern_red"
const CHURCH := "building_church_blue"
const SMITHY := "building_blacksmith_green"
const MARKET := "building_market_yellow"
const WELL := "building_well_blue"
const FENCE := "fence_wood_straight"
const GATE := "fence_wood_straight_gate"
const PROPS: Array[String] = ["barrel", "crate_A_big", "crate_B_small"]
## A fence piece is this long along its edge at scale 1.
const FENCE_LENGTH := 1.1547
## The well is drawn a little smaller than the buildings, to fit the 3x3 cells it stands on; barrels and crates too.
const WELL_FIT := 0.75
const PROP_FIT := 0.5


## The model of a building. A house with a six-cell deep lot is the big house.
static func building_name(building: Village.Building) -> String:
	match building.kind:
		Village.Kind.INN:
			return INN
		Village.Kind.CHURCH:
			return CHURCH
		Village.Kind.SMITHY:
			return SMITHY
		Village.Kind.MARKET:
			return MARKET
	var big := maxi(building.rect.size.x, building.rect.size.y) > 5
	var houses := BIG_HOUSES if big else SMALL_HOUSES
	return houses[building.variant % houses.size()]


## A model by file name, at a scale.
static func load_model(model_name: String, scale: float) -> Node3D:
	var model: Node3D = load(PATH % model_name).instantiate()
	model.scale = Vector3.ONE * scale
	return model


## The box a model fills (position and size in cells, at its current scale), seen from its own origin.
static func bounds_of(model: Node3D) -> AABB:
	var result := _bounds_below(model, Transform3D.IDENTITY)
	return AABB(result.position * model.scale, result.size * model.scale)


static func _bounds_below(node: Node, to_root: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var box := AABB()
		var has_box := false
		if child is Node3D:
			var here: Transform3D = to_root * child.transform
			if child is MeshInstance3D:
				box = here * child.get_aabb()
				has_box = true
			var below := _bounds_below(child, here)
			if below.size != Vector3.ZERO:
				box = box.merge(below) if has_box else below
				has_box = true
		if has_box:
			result = box if first else result.merge(box)
			first = false
	return result


## Every mesh of a model.
static func meshes_of(model: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is MeshInstance3D:
			meshes.append(node)
	return meshes
