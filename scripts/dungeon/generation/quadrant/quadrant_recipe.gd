class_name QuadrantRecipe
extends RefCounted
## What a quadrant is made of, as plain data: its size, the mix of terrain, how thick the border is, how clear
## the middle stays and which set pieces go in. QuadrantGenerator runs the generation steps by it; the same
## recipe and seed always make the same map. The plains is the first recipe; later quadrants are new ones.
## The numbers are tunable (Tune → World, see knobs), and the defaults live here.

## Bumped whenever the same recipe and seed would make a different map.
const VERSION := 1
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
## The hero starts in the middle; this many cells around it stay clear (the village replaces that spot later).
var safe_ring := 20
## The crypt entrance lies at least this far out from the middle (0 the middle, 1 the border; see outward).
var crypt_min_outward := 0.5


## The plains: the centre quadrant, with every number as listed above.
static func plains() -> QuadrantRecipe:
	return QuadrantRecipe.new()


## The same quadrant with nothing in the way: no groves, boulders or ponds. Always valid (see QuadrantGenerator).
func without_obstacles() -> QuadrantRecipe:
	var plain := QuadrantRecipe.new()
	for knob in knobs():
		plain.set(knob.field, get(knob.field))
	plain.grove_share = 0.0
	plain.boulder_count = 0
	plain.pond_count = 0
	return plain


func size() -> Vector2i:
	return Vector2i(width, height)


func center() -> Vector2i:
	return size() / 2


## The cells inside the border.
func interior() -> Rect2i:
	return Rect2i(Vector2i.ONE * border_thickness, size() - Vector2i.ONE * border_thickness * 2)


## How far out a cell lies: 0 in the middle, 1 at the edge of the map, measured to the nearest side in the same
## proportion on both axes.
func outward(cell: Vector2i) -> float:
	var offset := Vector2(cell - center()).abs()
	return maxf(offset.x / (width / 2.0), offset.y / (height / 2.0))


## The pieces to stamp in, in order (see SetPiecePlacer).
func set_pieces() -> Array[SetPiece]:
	return [SetPieces.crypt_entrance(crypt_min_outward)]


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
		Knob.new("safe_ring", "Clear ring around the start", 5, 40, 1),
		Knob.new("crypt_min_outward", "Crypt entrance, least out (0-1)", 0.2, 0.9, 0.05),
	]
