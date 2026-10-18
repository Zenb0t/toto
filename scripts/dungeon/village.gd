class_name Village
extends RefCounted
## The village as a map knows it (see DungeonMap.village): where it lies, its gates, its buildings, the inn's
## doorstep and the well. Plain data, read back from the map's ASCII by DungeonMapParser, and the home of the
## letters the village is drawn with, which the village generator writes and the parser reads.

enum Kind { HOUSE, INN, CHURCH, SMITHY, MARKET }

const INN := "I"
const CHURCH := "C"
const SMITHY := "S"
const MARKET := "M"
## Houses are drawn with a digit, one per colour, so a house's colour travels in the map.
const HOUSE_LETTERS := "1234"
const HOUSE_COLORS := 4
## The palisade around the village, and the gap through it on each side.
const PALISADE := "Y"
const GATE := "G"
const WELL := "U"
## A barrel or crate: solid, but low enough to see over.
const PROP := "X"
## The cell in front of the inn's door: where the hero rests.
const DOORSTEP := "D"
## Beaten earth: the streets and the square (walkable).
const STREET := ":"
## The hero's start on beaten earth: a `P` that doesn't turn the street under it into grass.
const START := "@"


## A building: its kind, its colour (houses only: 0 to HOUSE_COLORS - 1) and the cells it covers.
class Building:
	extends RefCounted
	var kind: Kind
	var variant: int
	var rect: Rect2i
	## The way its door faces (toward the street), as a step: Vector2i.DOWN is south, toward the camera.
	var facing: Vector2i

	func _init(building_kind: Kind, building_variant: int, area: Rect2i, door_faces := Vector2i.DOWN) -> void:
		kind = building_kind
		variant = building_variant
		rect = area
		facing = door_faces


## Everything inside the palisade, the palisade included.
var area: Rect2i
## The cells of every gate.
var gates: Array[Vector2i] = []
## The inn's doorstep, or DungeonMap.NO_CELL if the village has no inn.
var inn_doorstep := DungeonMap.NO_CELL
var well_cell := DungeonMap.NO_CELL
var buildings: Array[Building] = []


func _init(village_area := Rect2i()) -> void:
	area = village_area


func contains(cell: Vector2i) -> bool:
	return area.has_point(cell)


## Every cell inside the palisade, the palisade included.
func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			result.append(Vector2i(x, y))
	return result


## The building covering a cell, or null.
func building_at(cell: Vector2i) -> Building:
	for building in buildings:
		if building.rect.has_point(cell):
			return building
	return null


## The first building of a kind, or null (there is one inn, but many houses).
func building_of(kind: Kind) -> Building:
	for building in buildings:
		if building.kind == kind:
			return building
	return null


## The letter that draws a building's cells.
static func letter_of(kind: Kind, variant := 0) -> String:
	match kind:
		Kind.INN:
			return INN
		Kind.CHURCH:
			return CHURCH
		Kind.SMITHY:
			return SMITHY
		Kind.MARKET:
			return MARKET
	return HOUSE_LETTERS[clampi(variant, 0, HOUSE_COLORS - 1)]


## Whether a letter draws a building's cell.
static func is_building_letter(letter: String) -> bool:
	return letter != "" and (letter in [INN, CHURCH, SMITHY, MARKET] or HOUSE_LETTERS.contains(letter))


static func kind_of_letter(letter: String) -> Kind:
	match letter:
		INN:
			return Kind.INN
		CHURCH:
			return Kind.CHURCH
		SMITHY:
			return Kind.SMITHY
		MARKET:
			return Kind.MARKET
	return Kind.HOUSE


static func variant_of_letter(letter: String) -> int:
	return maxi(HOUSE_LETTERS.find(letter), 0)


## Letters nobody can walk through: the palisade, the well, props and buildings.
static func solid_letters() -> Array[String]:
	var letters: Array[String] = [PALISADE, WELL, PROP, INN, CHURCH, SMITHY, MARKET]
	for letter in HOUSE_LETTERS:
		letters.append(letter)
	return letters
