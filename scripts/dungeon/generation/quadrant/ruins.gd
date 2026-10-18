class_name Ruins
extends RefCounted
## The ruin: a walled courtyard of crumbled stone in a corner of the plains, holding the map's toughest band and a
## guaranteed chest. Hand-written in the map format (see Vaults) at 25x19, with a broken shrine in the middle where
## the chest stands. Its wall has four places where a gap could be (the `o` cells, three wide); the generator opens
## two or three of them by the recipe, so the hero chooses how to go in, and mirrors the drawing so one design
## reads as up to four. Walls are ordinary walls, the rubble boulders. Pure: the caller passes the random numbers.

const ID := "ruin"
## The ruin's number: the id of its band (see Band.home_of) and of its chest in the map's record (see
## MapRecord.open_chest). Camps' band ids start at Camps.FIRST_BAND_ID and room numbers count up from 0, so
## neither is ever this.
const NUMBER := 2_000_000
## The chest's cell on the map: the ruin's middle, which is also the home of its band.
const CHEST := "$"
## A place in the wall where a gap could be, until the generator opens it or closes it.
const GAP := "o"
const SIZE := Vector2i(25, 19)
## The share of the ruin's band that starts wandering: all of it, always (see Band.start_of).
const WANDERING_SHARE := 1.0
## The ruin's anchor lies this share of the way out to the border, along both axes at least: in a corner.
const CORNER_SHARE := 0.4
## Its monsters stand and wander within this many cells (either way) of the chest.
const BAND_RADIUS_CELLS := 6
## Where the band's monsters stand, as offsets from the chest, in the order the band fills them. Every one is
## open floor in the drawing, however it is mirrored.
const BAND_SLOTS: Array[Vector2i] = [
	Vector2i(-4, -1), Vector2i(4, 1), Vector2i(4, -1), Vector2i(-4, 1),
	Vector2i(0, -4), Vector2i(0, 4), Vector2i(-6, 0), Vector2i(6, 0),
	Vector2i(-2, -4), Vector2i(2, 4), Vector2i(2, -4), Vector2i(-2, 4),
]
const DESIGN: Array[String] = [
	"###########ooo###########",
	"#.......................#",
	"#.###...............###.#",
	"#.#...................#.#",
	"#.#.....B.............#.#",
	"#.......................#",
	"#.....##.........##.....#",
	"#........###.###........#",
	"o........#.....#........o",
	"o...........$...........o",
	"o........#.....#........o",
	"#........###.###........#",
	"#.....##.........##.....#",
	"#.......................#",
	"#.#.............B.....#.#",
	"#.#...................#.#",
	"#.###...............###.#",
	"#.......................#",
	"###########ooo###########",
]


## How many monsters the ruin's band holds: the recipe's, but always more than the biggest camp can have, so the
## ruin's band is the toughest (see band_letters).
static func band_size(recipe: QuadrantRecipe) -> int:
	var biggest_camp := maxi(recipe.camp_size_min, recipe.camp_size_max)
	return mini(maxi(recipe.ruin_band_size, biggest_camp + 1), BAND_SLOTS.size())


## The map letters of the ruin's band (see Bestiary). It is made like the band of a camp at the very edge of the map
## (goblins and archers, no kobolds), but bigger than any camp's, so its threat is above every camp's.
static func band_letters(recipe: QuadrantRecipe) -> Array[String]:
	var size := band_size(recipe)
	var archers := clampi(floori(size * CampCrews.ARCHER_SHARE_AT_EDGE), 0, size - 1)
	var letters: Array[String] = []
	for _i in size - archers:
		letters.append("g")
	for _i in archers:
		letters.append("a")
	return letters


## The ruin's drawing for this try: some of the possible gaps opened, mirrored, the band standing in the courtyard.
static func draw(recipe: QuadrantRecipe, rng: RandomNumberGenerator) -> PackedStringArray:
	var most := clampi(maxi(recipe.ruin_gaps_min, recipe.ruin_gaps_max), 1, 4)
	var least := clampi(mini(recipe.ruin_gaps_min, recipe.ruin_gaps_max), 1, most)
	var open_sides := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	_shuffle(open_sides, rng)
	open_sides = open_sides.slice(0, rng.randi_range(least, most))
	var flip_x := rng.randi() % 2 == 0
	var flip_y := rng.randi() % 2 == 0
	var rows: Array[String] = []
	for y in SIZE.y:
		var row := ""
		for x in SIZE.x:
			var symbol := DESIGN[SIZE.y - 1 - y if flip_y else y][SIZE.x - 1 - x if flip_x else x]
			if symbol == GAP:
				symbol = "." if _side_of(Vector2i(x, y)) in open_sides else DungeonMapParser.WALL
			row += symbol
		rows.append(row)
	var letters := band_letters(recipe)
	for i in letters.size():
		var cell := chest_offset() + BAND_SLOTS[i]
		rows[cell.y] = rows[cell.y].substr(0, cell.x) + letters[i] + rows[cell.y].substr(cell.x + 1)
	return PackedStringArray(rows)


## Where the chest stands inside the drawing, however it is mirrored: the exact middle.
static func chest_offset() -> Vector2i:
	return SIZE / 2


## The ruin's rectangle on a map, from its chest cell.
static func rect_around(chest_cell: Vector2i) -> Rect2i:
	return Rect2i(chest_cell - chest_offset(), SIZE)


## Whether a monster spawning at this cell belongs to the ruin's band, on a map whose ruin has its chest at `chest_cell`.
static func is_home_of(chest_cell: Vector2i, spawn_cell: Vector2i) -> bool:
	var apart := (spawn_cell - chest_cell).abs()
	return maxi(apart.x, apart.y) <= BAND_RADIUS_CELLS


## Which side of the ruin a wall cell of the drawing lies on (UP the top row, and so on).
static func _side_of(cell: Vector2i) -> Vector2i:
	if cell.y == 0:
		return Vector2i.UP
	if cell.y == SIZE.y - 1:
		return Vector2i.DOWN
	return Vector2i.LEFT if cell.x == 0 else Vector2i.RIGHT


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept: Variant = items[i]
		items[i] = items[j]
		items[j] = kept
