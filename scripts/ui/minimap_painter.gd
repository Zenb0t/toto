class_name MinimapPainter
extends RefCounted
## Paints the minimap as a tiny picture with one pixel per cell: only what the player has seen, the cells
## in view brighter than the ones remembered, with the stairs, campfires and the player marked. Outdoors it also shows the
## tree groves, boulders and exits. Knows no nodes.

const FLOOR_COLOR := Color(0.62, 0.6, 0.68)
const WATER_COLOR := Color(0.25, 0.45, 0.85)
const LAVA_COLOR := Color(0.95, 0.4, 0.12)
const DOOR_COLOR := Color(0.65, 0.45, 0.25)
const EXIT_COLOR := Color(1.0, 0.85, 0.2)
const STAIRS_UP_COLOR := Color(0.85, 0.88, 0.95)
## Outdoors: tree groves, boulders and the barricades across the quadrant's exits.
const GROVE_COLOR := Color(0.2, 0.45, 0.22)
const BOULDER_COLOR := Color(0.5, 0.5, 0.48)
const BARRICADE_COLOR := Color(0.85, 0.5, 0.2)
const CAMPFIRE_COLOR := Color(1.0, 0.55, 0.15)
const PLAYER_COLOR := Color(0.3, 1.0, 0.9)
## Cells seen before but out of view are drawn this much darker.
const REMEMBERED_SHADE := 0.55


static func paint(map: DungeonMap, exploration: Exploration, player_cell: Vector2i) -> Image:
	var image := Image.create(map.size.x, map.size.y, false, Image.FORMAT_RGBA8)
	for y in map.size.y:
		for x in map.size.x:
			var cell := Vector2i(x, y)
			if (map.is_open(cell) or map.blocker_at(cell) != DungeonMap.NO_BLOCKER) and exploration.is_seen(cell):
				image.set_pixelv(cell, _shaded(_color_of(map, cell), exploration.is_visible(cell)))
	if Rect2i(Vector2i.ZERO, map.size).has_point(player_cell):
		image.set_pixelv(player_cell, PLAYER_COLOR)
	return image


static func _color_of(map: DungeonMap, cell: Vector2i) -> Color:
	match map.blocker_at(cell):
		DungeonMap.Blocker.GROVE:
			return GROVE_COLOR
		DungeonMap.Blocker.BOULDER:
			return BOULDER_COLOR
		DungeonMap.Blocker.BARRICADE:
			return BARRICADE_COLOR
	if map.is_campfire(cell):
		return CAMPFIRE_COLOR
	if cell == map.exit_cell:
		return EXIT_COLOR
	if cell == map.stairs_up_cell:
		return STAIRS_UP_COLOR
	if map.is_door(cell):
		return DOOR_COLOR
	match map.terrain_at(cell):
		DungeonMap.Terrain.WATER, DungeonMap.Terrain.SHALLOW:
			return WATER_COLOR
		DungeonMap.Terrain.LAVA:
			return LAVA_COLOR
	return FLOOR_COLOR


static func _shaded(color: Color, in_view: bool) -> Color:
	return color if in_view else color.darkened(REMEMBERED_SHADE)
