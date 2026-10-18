class_name QuadrantRecipe
extends RefCounted
## What a quadrant is made of, as plain data: its size, the mix of terrain, how thick the border is, how big
## the village in the middle is and which set pieces go in. QuadrantGenerator runs the generation steps by it; the same
## recipe and seed always make the same map. The plains is the first recipe; later quadrants are new ones.
## The numbers are tunable (Tune → World, see knobs), and the defaults live here.

## Bumped whenever the same recipe and seed would make a different map.
const VERSION := 5
## The first lone campfire lies at most this many cells beyond the village's clear radius (see village_radius).
const NEAR_CAMPFIRE_BEYOND_VILLAGE := 12
## Each side's quadrant exit is this many cells wide, in the middle of the side.
const EXIT_WIDTH := 3

## Stable identifier; also the prefix of its tuning keys.
var id := "plains"
var width := 160
var height := 90
## The share of the cells inside the border that can be walked on (not trees, boulders, deep water).
var min_walkable_share := 0.7
## How many cells thick the forest border is.
var border_thickness := 5
## The share of the cells inside the border that are tree groves, before ponds and clearings take their part.
var grove_share := 0.16
## About how many cells across a grove is (the noise's feature size).
var grove_size := 14
var boulder_count := 70
var pond_count := 6
## A pond's deep water is about this many cells from its middle to its edge, plus a shallow shore around it.
var pond_radius_min := 3
var pond_radius_max := 6
## The village in the middle of the plains (see VillageGenerator): its size, and the share of its leftover ground
## that gets barrels and crates.
var village_width := 36
var village_height := 28
var village_prop_share := 0.15
## How much bigger than the models themselves the village's buildings, well and palisade are drawn (KayKit's
## Medieval Hexagon pieces are tiny next to a cell).
var building_scale := 6.0
## The crypt entrance lies at least this far out from the middle (0 the middle, 1 the border; see outward).
var crypt_min_outward := 0.5
## Camps: each a band of monsters round a campfire, tougher the farther out (see CampCrews).
var camp_count := 6
## The least distance in cells between two camps' campfires.
var camp_spacing := 18
## How many monsters a camp holds: the nearest camps the least, the farthest the most.
var camp_size_min := 2
var camp_size_max := 4
## The chance that a camp's band starts asleep rather than wandering about its fire.
var camp_asleep_chance := 0.5
## Lone campfires, scenery until they become places to rest; the first lies close to the village.
var campfire_count := 3
var campfire_spacing := 35
## The least distance in cells between a lone campfire and any camp.
var campfire_camp_gap := 12
## Dirt roads from the village gates to this many of the four exits (see QuadrantRoads), and how much they wander: 0 runs
## them straight where nothing is in the way, more sends them along the noise's valleys.
## The ruin in one corner (see Ruins): how many of its four possible wall gaps are open (a number between the least and
## the most, rolled per map), and how many monsters its band holds at least. The band always has more than the biggest
## camp's, so it is the map's toughest.
## Whether the quadrant has a ruin at all (only a recipe made by without_ruin has none).
var has_ruin := true
var ruin_gaps_min := 2
var ruin_gaps_max := 3
var ruin_band_size := 7
var road_count := 2
var road_bend := 3.0


## The plains: the centre quadrant, with every number as listed above.
static func plains() -> QuadrantRecipe:
	return QuadrantRecipe.new()


## The same quadrant with nothing in the way: no groves, boulders or ponds. Always valid (see QuadrantGenerator).
func without_obstacles() -> QuadrantRecipe:
	var plain := _copy()
	plain.grove_share = 0.0
	plain.boulder_count = 0
	plain.pond_count = 0
	return plain


## The same quadrant with no camps or campfires: the last resort for a size that has no room for them.
func without_camps() -> QuadrantRecipe:
	var empty := _copy()
	empty.camp_count = 0
	empty.campfire_count = 0
	return empty


## The same quadrant without its ruin: the last resort for a size too small to fit one in a corner beside the village.
func without_ruin() -> QuadrantRecipe:
	var open := _copy()
	open.has_ruin = false
	return open


func _copy() -> QuadrantRecipe:
	var copy := QuadrantRecipe.new()
	for knob in knobs():
		copy.set(knob.field, get(knob.field))
	copy.has_ruin = has_ruin
	return copy


func size() -> Vector2i:
	return Vector2i(width, height)


func village_size() -> Vector2i:
	return Vector2i(village_width, village_height)


## Round the middle, this far out stays clear of ponds and groves (the village and the grass round it).
func village_radius() -> float:
	return Vector2(village_size()).length() / 2.0 + SetPieces.VILLAGE_APRON


func center() -> Vector2i:
	return size() / 2


## The cells inside the border.
func interior() -> Rect2i:
	return Rect2i(Vector2i.ONE * border_thickness, size() - Vector2i.ONE * border_thickness * 2)


## Which corner of the map a cell lies toward: (-1 or 1, -1 or 1) for left/right and top/bottom of the middle.
func corner_of(cell: Vector2i) -> Vector2i:
	var offset := cell - center()
	return Vector2i(1 if offset.x >= 0 else -1, 1 if offset.y >= 0 else -1)


## How far out along each axis a cell lies, 0 (the middle line) to 1 (the edge of the map).
func outward_by_axis(cell: Vector2i) -> Vector2:
	var offset := Vector2(cell - center()).abs()
	return Vector2(offset.x / (width / 2.0), offset.y / (height / 2.0))


## How far out a cell lies: 0 in the middle, 1 at the edge of the map, measured to the nearest side in the same
## proportion on both axes.
func outward(cell: Vector2i) -> float:
	var offset := Vector2(cell - center()).abs()
	return maxf(offset.x / (width / 2.0), offset.y / (height / 2.0))


## The pieces to stamp in after the village, in order (see SetPiecePlacer).
func set_pieces() -> Array[SetPiece]:
	var pieces: Array[SetPiece] = [SetPieces.crypt_entrance(crypt_min_outward)]
	for i in campfire_count:
		var fire := SetPieces.campfire(campfire_spacing, campfire_camp_gap)
		pieces.append(fire.near_centre(village_radius() + NEAR_CAMPFIRE_BEYOND_VILLAGE) if i == 0 else fire)
	for _i in camp_count:
		pieces.append(SetPieces.camp(camp_spacing, campfire_camp_gap))
	return pieces


## The share of camp bands that start wandering (the rest sleep; see Band.start_of).
func camp_wandering_share() -> float:
	return 1.0 - camp_asleep_chance


func knobs() -> Array[Knob]:
	return [
		Knob.new("width", "Width (cells)", 100, 260, 10),
		Knob.new("height", "Height (cells)", 60, 150, 10),
		Knob.new("min_walkable_share", "Walkable at least", 0.5, 0.95, 0.01),
		Knob.new("border_thickness", "Forest border (cells)", 3, 10, 1),
		Knob.new("grove_share", "Tree groves (share)", 0.0, 0.4, 0.01),
		Knob.new("grove_size", "Grove size (cells)", 4, 40, 1),
		Knob.new("boulder_count", "Boulders", 0, 300, 5),
		Knob.new("pond_count", "Ponds", 0, 20, 1),
		Knob.new("pond_radius_min", "Pond radius, least", 2, 8, 1),
		Knob.new("pond_radius_max", "Pond radius, most", 3, 12, 1),
		Knob.new("village_width", "Village width (cells)", 24, 60, 2),
		Knob.new("village_height", "Village height (cells)", 20, 44, 2),
		Knob.new("village_prop_share", "Village barrels and crates (share)", 0.0, 0.4, 0.01),
		Knob.new("building_scale", "Village art scale (x)", 2.0, 10.0, 0.5),
		Knob.new("crypt_min_outward", "Crypt entrance, least out (0-1)", 0.2, 0.9, 0.05),
		Knob.new("camp_count", "Camps", 0, 10, 1),
		Knob.new("camp_spacing", "Camps, least apart (cells)", 8, 40, 1),
		Knob.new("camp_size_min", "Camp band, nearest (monsters)", 1, 6, 1),
		Knob.new("camp_size_max", "Camp band, farthest (monsters)", 1, 8, 1),
		Knob.new("camp_asleep_chance", "Camps asleep (chance)", 0.0, 1.0, 0.05),
		Knob.new("campfire_count", "Lone campfires", 0, 6, 1),
		Knob.new("campfire_spacing", "Campfires, least apart (cells)", 10, 60, 1),
		Knob.new("campfire_camp_gap", "Campfire from a camp, least (cells)", 4, 30, 1),
		Knob.new("ruin_gaps_min", "Ruin wall gaps, least", 1, 4, 1),
		Knob.new("ruin_gaps_max", "Ruin wall gaps, most", 1, 4, 1),
		Knob.new("ruin_band_size", "Ruin band (monsters, least)", 4, 12, 1),
		Knob.new("road_count", "Dirt roads to exits", 0, 4, 1),
		Knob.new("road_bend", "Road wander", 0.0, 8.0, 0.5),
	]
