class_name QuadrantExits
extends RefCounted
## The third generation step: a quadrant exit in the middle of each of the four sides. Each is a lane through the
## forest border, QuadrantRecipe.EXIT_WIDTH cells wide, with a barricade across its outer end (the way is shut
## until the neighbouring quadrant exists), and a cleared approach inside the border so the lane is never lost in
## a grove. Pure.

## Sides, as the direction one goes to leave the quadrant.
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## The ground cleared inside the border, in front of a lane, and to each side of it.
const APPROACH_DEPTH := 4
const APPROACH_SIDE := 2


static func cut(grid: QuadrantGrid, recipe: QuadrantRecipe) -> void:
	for side in SIDES:
		grid.fill_rect(lane(recipe, side), QuadrantGrid.GRASS)
		grid.fill_rect(approach(recipe, side), QuadrantGrid.GRASS)
		for cell in barricade_cells(recipe, side):
			grid.put(cell, QuadrantGrid.BARRICADE)


## The cells of the barricade across a side's exit: the outermost row (or column) of the map, in its middle.
static func barricade_cells(recipe: QuadrantRecipe, side: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var half := QuadrantRecipe.EXIT_WIDTH / 2
	for offset in range(-half, half + 1):
		cells.append(_edge_cell(recipe, side, offset))
	return cells


## The walkable cell right in front of a side's barricade, in the middle of the lane.
static func front_cell(recipe: QuadrantRecipe, side: Vector2i) -> Vector2i:
	return _edge_cell(recipe, side, 0) - side


## The lane through the forest border.
static func lane(recipe: QuadrantRecipe, side: Vector2i) -> Rect2i:
	return _strip(recipe, side, QuadrantRecipe.EXIT_WIDTH / 2, 0, recipe.border_thickness)


## The cleared ground just inside the border, a little wider than the lane.
static func approach(recipe: QuadrantRecipe, side: Vector2i) -> Rect2i:
	return _strip(recipe, side, QuadrantRecipe.EXIT_WIDTH / 2 + APPROACH_SIDE, recipe.border_thickness, APPROACH_DEPTH)


## Everything a side's exit keeps clear.
static func cleared_areas(recipe: QuadrantRecipe) -> Array[Rect2i]:
	var areas: Array[Rect2i] = []
	for side in SIDES:
		areas.append(lane(recipe, side))
		areas.append(approach(recipe, side))
	return areas


## A strip leading in from the side's edge: `inset` cells in, `depth` cells long, `half_width` to each side of
## the middle.
static func _strip(recipe: QuadrantRecipe, side: Vector2i, half_width: int, inset: int, depth: int) -> Rect2i:
	var across := Vector2i(absi(side.y), absi(side.x))
	var start := _edge_cell(recipe, side, 0) - side * inset
	var a := start - across * half_width
	var b := start + across * half_width - side * (depth - 1)
	var top_left := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var bottom_right := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	return Rect2i(top_left, bottom_right - top_left + Vector2i.ONE)


static func _edge_cell(recipe: QuadrantRecipe, side: Vector2i, offset: int) -> Vector2i:
	var middle := recipe.center()
	if side.y != 0:
		return Vector2i(middle.x + offset, 0 if side.y < 0 else recipe.height - 1)
	return Vector2i(0 if side.x < 0 else recipe.width - 1, middle.y + offset)
