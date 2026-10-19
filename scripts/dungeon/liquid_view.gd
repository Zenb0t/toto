class_name LiquidView
extends RefCounted
## Water and lava with slowly moving waves (shaders/liquid.gdshader), laid on the floor in square pieces (see
## FloorChunk) that share one material, so the waves run on across the pieces' edges.

const SHADER := preload("res://shaders/liquid.gdshader")


## The pieces showing every cell of one liquid.
static func pieces(cells: Array[Vector2i], deep: Color, shine: Color, speed: float) -> Array[FloorChunk]:
	var waves := ShaderMaterial.new()
	waves.shader = SHADER
	waves.set_shader_parameter("deep_color", deep)
	waves.set_shader_parameter("shine_color", shine)
	waves.set_shader_parameter("speed", speed)
	var result: Array[FloorChunk] = []
	for piece_cells: Array[Vector2i] in FloorChunk.split(cells):
		var piece := FloorChunk.new(piece_cells, _paint)
		piece.material = waves
		result.append(piece)
	return result


## Each cell is a plain square: the shader colours it.
static func _paint(canvas: CanvasItem, cells: Array[Vector2i]) -> void:
	for cell in cells:
		canvas.draw_rect(Rect2(Vector2(cell) * DungeonView.TILE_SIZE, Vector2.ONE * DungeonView.TILE_SIZE), Color.WHITE)
