class_name MapStage
extends Node2D
## One map in the running game, built from its spec: the plan (DungeonMap), how enemies find their way
## (Pathfinder), what the hero has seen (Exploration, which knows the village from the start), and the nodes that show it: the floor and walls
## (DungeonView), the fog (FogView) and the 3D view (WorldView3D). Actors, loot and attacks go under it, so
## leaving the map frees it whole and the next map is built the same way. Holds no game rules.

var spec: MapSpec
var map: DungeonMap
var pathfinder: Pathfinder
var exploration := Exploration.new()
var view := DungeonView.new()
var fog: FogView
var world := WorldView3D.new()


## Generates and reads the map; the nodes that show it are built once the stage is in the tree.
func _init(map_spec: MapSpec) -> void:
	spec = map_spec
	map = DungeonMapParser.new().parse(map_spec.ascii())
	pathfinder = Pathfinder.new(map)
	# A village is home: the hero knows it all before taking a step.
	if map.village != null:
		exploration.restore(map.village.cells())


func _ready() -> void:
	var look := spec.branch().look
	add_child(view)
	view.show_map(map, look)
	fog = FogView.new(map.size, view.drawn_cells())
	add_child(fog)
	add_child(world)
	world.show_world(self, map, view.wall_cells(), look)


## Loot lies just above the floor, below the actors.
func add_on_floor(node: Node2D) -> void:
	add_child(node)
	move_child(node, view.get_index() + 1)


## Actors walk under the fog.
func add_actor(node: Node2D) -> void:
	add_child(node)
	move_child(node, fog.get_index())


## Attacks and their effects show over everything.
func add_effect(node: Node2D) -> void:
	add_child(node)
