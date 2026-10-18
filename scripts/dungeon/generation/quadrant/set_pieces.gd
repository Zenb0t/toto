class_name SetPieces
extends RefCounted
## The hand-made pieces the quadrant recipes stamp (see SetPiece and SetPiecePlacer). Pure data; the map
## format's letters are the ones DungeonMapParser reads.

## Open grass kept round the village, outside its palisade.
const VILLAGE_APRON := 3


## A small stone mausoleum, 5x5, with its door on the side facing the camera and stairs down inside: the way
## into the crypt. The hero enters by stepping onto the stairs and comes back out onto them.
static func crypt_entrance(min_outward: float) -> SetPiece:
	return SetPiece.new("crypt_entrance", PackedStringArray([
		"#####",
		"#...#",
		"#.>.#",
		"#...#",
		"##.##",
	]), QuadrantGrid.CRYPT_ENTRANCE, min_outward)


## The village: a palisaded settlement in the middle of the plains, with the hero's start in front of the inn. The
## drawing is made by VillageGenerator; the placer puts it in the very middle, with a margin of open grass round it.
static func village(drawing: VillageGenerator.Result) -> SetPiece:
	return SetPiece.new("village", drawing.rows, QuadrantGrid.START, 0.0, VILLAGE_APRON, true)
