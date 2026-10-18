class_name SetPieces
extends RefCounted
## The hand-made pieces the quadrant recipes stamp (see SetPiece and SetPiecePlacer). Pure data; the map
## format's letters are the ones DungeonMapParser reads.


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
