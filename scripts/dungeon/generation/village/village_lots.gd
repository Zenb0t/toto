class_name VillageLots
extends RefCounted
## The village lots, hand-written like the vaults (see Vaults): each is a drawing in the map format of a building
## with its doorstep, and the things that always stand by it (a barrel by the door). Every drawing faces south: the
## door is on the bottom row, whose `D` is the doorstep. The packer (VillageLotPacker) turns it to face its street and
## may mirror it, so one drawing reads as up to eight. `H` is a house wall: it takes its colour when the village is
## done. A lot is a plain rectangle: the building and, in front of it, one row of ground.
## Pure data.

const HOUSE_WALL := "H"

## Which designs are houses, which are the specials a village has one or two of, and the inn.
const HOUSES: Array[String] = ["house_a", "house_b"]
const SPECIALS: Array[String] = ["smithy", "market", "church"]
const INN := "inn"

## The kind of building each design draws.
const KINDS := {
	"house_a": Village.Kind.HOUSE,
	"house_b": Village.Kind.HOUSE,
	"inn": Village.Kind.INN,
	"smithy": Village.Kind.SMITHY,
	"market": Village.Kind.MARKET,
	"church": Village.Kind.CHURCH,
}

## Sizes follow KayKit's Medieval Hexagon pieces at the default scale of 6 (see BuildingModel).
const DESIGNS := {
	"house_a": """
HHHHH
HHHHH
HHHHH
HHHHH
HHHHH
X.D..
""",
	"house_b": """
HHHHH
HHHHH
HHHHH
HHHHH
HHHHH
HHHHH
..D.X
""",
	"inn": """
IIIIIII
IIIIIII
IIIIIII
IIIIIII
IIIIIII
IIIIIII
IIIIIII
IIIIIII
X..D..X
""",
	"smithy": """
SSSSSSSS
SSSSSSSS
SSSSSSSS
SSSSSSSS
SSSSSSSS
SSSSSSSS
SSSSSSSS
X..D....
""",
	"market": """
MMMMMMMMMMM
MMMMMMMMMMM
MMMMMMMMMMM
MMMMMMMMMMM
MMMMMMMMMMM
MMMMMMMMMMM
MMMMMMMMMMM
MMMMMMMMMMM
X....D....X
""",
	"church": """
CCCCCC
CCCCCC
CCCCCC
CCCCCC
CCCCCC
CCCCCC
CCCCCC
..D...
""",
}


## A lot as it can be stamped: turned a quarter turn at a time and maybe mirrored, so its doorstep faces a direction.
class Variant:
	extends RefCounted
	var lot_id: String
	var kind: Village.Kind
	var rows: PackedStringArray
	## Where the doorstep is in the drawing.
	var doorstep: Vector2i
	## The way the door faces: from the building toward its street.
	var facing: Vector2i

	func _init(
			id: String, building_kind: Village.Kind, drawing: PackedStringArray, door: Vector2i, facing_toward: Vector2i
	) -> void:
		lot_id = id
		kind = building_kind
		rows = drawing
		doorstep = door
		facing = facing_toward

	func size() -> Vector2i:
		return Vector2i(rows[0].length(), rows.size())


## The drawing of a lot, facing south, one string per row.
static func rows_of(lot_id: String) -> PackedStringArray:
	return PackedStringArray(DESIGNS[lot_id].strip_edges().split("\n"))


## Every way a lot can stand: four facings, each mirrored or not.
static func variants(lot_id: String) -> Array[Variant]:
	var result: Array[Variant] = []
	for mirrored in [false, true]:
		var rows := rows_of(lot_id)
		if mirrored:
			rows = _mirrored(rows)
		var facing := Vector2i.DOWN
		for _turn in 4:
			result.append(Variant.new(lot_id, KINDS[lot_id], rows, _find(rows, Village.DOORSTEP), facing))
			rows = _turned_clockwise(rows)
			facing = Vector2i(-facing.y, facing.x)
	return result


static func _find(rows: PackedStringArray, symbol: String) -> Vector2i:
	for y in rows.size():
		var x := rows[y].find(symbol)
		if x >= 0:
			return Vector2i(x, y)
	push_error("Village lot has no '%s'" % symbol)
	return Vector2i.ZERO


static func _mirrored(rows: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for row in rows:
		var flipped := ""
		for x in range(row.length() - 1, -1, -1):
			flipped += row[x]
		result.append(flipped)
	return result


## A quarter turn clockwise: the top row becomes the right column. A door facing south then faces west.
static func _turned_clockwise(rows: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for x in rows[0].length():
		var row := ""
		for y in range(rows.size() - 1, -1, -1):
			row += rows[y][x]
		result.append(row)
	return result
