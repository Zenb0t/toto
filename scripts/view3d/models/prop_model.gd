class_name PropModel
extends RefCounted
## Furnishings from KayKit's Dungeon Remastered pack (CC0, by Kay Lousberg; see assets/kaykit_dungeon).
## Its pieces are built four units to a wall; one of our cells is one unit.

const PATH := "res://assets/kaykit_dungeon/%s.glb"
## The pack's size, in our units.
const SCALE := 0.25
## Small things that lie about the floor (see DungeonDecor.clutter_cells).
const CLUTTER: Array[String] = ["candle_lit", "candle_triple", "bottle_A_brown", "coin_stack_small"]
const BANNERS: Array[String] = ["banner_red", "banner_patternA_blue", "banner_shield_red"]
## Banners hang a little larger than the pack makes them, and lower, so they fill the wall.
const BANNER_SIZE := 1.3
const BANNER_DROP := 0.18


## A furnishing, sized for our cells (times size).
static func make(prop_name: String, size := 1.0) -> Node3D:
	var prop: Node3D = load(PATH % prop_name).instantiate()
	prop.scale = Vector3.ONE * SCALE * size
	return prop
