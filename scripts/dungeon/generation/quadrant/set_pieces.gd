class_name SetPieces
extends RefCounted
## The hand-made pieces the quadrant recipes stamp (see SetPiece and SetPiecePlacer). Pure data; the map
## format's letters are the ones DungeonMapParser reads.

## Open grass kept round the village, outside its palisade.
const VILLAGE_APRON := 3
const RUIN_ID := Ruins.ID


## The ruin, drawn by Ruins.draw: in a corner of the quadrant, never the crypt entrance's, with the chest in the middle
## as its anchor (so the placer makes sure it can be reached).
static func ruin(drawing: PackedStringArray) -> SetPiece:
	return SetPiece.new(RUIN_ID, drawing, Ruins.CHEST).in_corner(Ruins.CORNER_SHARE) \
		.in_other_corner_than([CRYPT_ENTRANCE_ID])


## A small stone mausoleum, 5x5, with its door on the side facing the camera and stairs down inside: the way
## into the crypt. The hero enters by stepping onto the stairs and comes back out onto them.
static func crypt_entrance(min_outward: float) -> SetPiece:
	return SetPiece.new("crypt_entrance", PackedStringArray([
		"#####",
		"#...#",
		"#.>.#",
		"#...#",
		"##.##",
	]), QuadrantGrid.CRYPT_ENTRANCE, min_outward).in_other_corner_than([RUIN_ID])


## The village: a palisaded settlement in the middle of the plains, with the hero's start in front of the inn. The
## drawing is made by VillageGenerator; the placer puts it in the very middle, with a margin of open grass round it.
static func village(drawing: VillageGenerator.Result) -> SetPiece:
	return SetPiece.new("village", drawing.rows, QuadrantGrid.START, 0.0, VILLAGE_APRON, true)
## Where a camp's monsters stand round its campfire (offsets from the fire), in the order the band fills them.
const CAMP_SLOTS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1),
	Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0),
]
const CAMP_RADIUS := 3
const CAMP_ID := "camp"
const CRYPT_ENTRANCE_ID := "crypt_entrance"
const CAMPFIRE_ID := "campfire"


## The ground of a camp: open grass, 7x7, with the campfire in the middle. Its monsters are drawn in later, by how
## far out the camp lies (see CampCrews). Camps keep camp_apart cells from each other and campfire_gap from the
## lone campfires.
static func camp(camp_apart: float, campfire_gap: float) -> SetPiece:
	return SetPiece.new(CAMP_ID, _open_ground(CAMP_RADIUS), QuadrantGrid.CAMPFIRE) \
		.spaced(CAMP_ID, {CAMP_ID: camp_apart, CAMPFIRE_ID: campfire_gap})


## A lone campfire on open grass: scenery until it becomes a place to rest. They keep campfire_apart cells from
## each other and campfire_gap from the camps.
static func campfire(campfire_apart: float, campfire_gap: float) -> SetPiece:
	return SetPiece.new(CAMPFIRE_ID, _open_ground(1), QuadrantGrid.CAMPFIRE) \
		.spaced(CAMPFIRE_ID, {CAMPFIRE_ID: campfire_apart, CAMP_ID: campfire_gap})


## A square of grass, `radius` cells out from a campfire in its middle.
static func _open_ground(radius: int) -> PackedStringArray:
	var rows := PackedStringArray()
	for y in radius * 2 + 1:
		var row := ".".repeat(radius * 2 + 1)
		if y == radius:
			row = row.substr(0, radius) + QuadrantGrid.CAMPFIRE + row.substr(radius + 1)
		rows.append(row)
	return rows
