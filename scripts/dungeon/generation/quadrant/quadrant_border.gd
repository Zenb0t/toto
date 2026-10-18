class_name QuadrantBorder
extends RefCounted
## The second generation step: a thick forest all round the quadrant, which marks the edge of the world.


static func raise(grid: QuadrantGrid, recipe: QuadrantRecipe) -> void:
	var inner := recipe.interior()
	for y in grid.size.y:
		for x in grid.size.x:
			if not inner.has_point(Vector2i(x, y)):
				grid.put(Vector2i(x, y), QuadrantGrid.GROVE)
