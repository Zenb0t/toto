class_name LiquidView
extends Node2D
## Draws every cell of one liquid (water or lava) with slowly moving waves (shaders/liquid.gdshader).

const SHADER := preload("res://shaders/liquid.gdshader")

var _cells: Array[Vector2i] = []


func _init(cells: Array[Vector2i], deep: Color, shine: Color, speed: float) -> void:
	_cells = cells
	var waves := ShaderMaterial.new()
	waves.shader = SHADER
	waves.set_shader_parameter("deep_color", deep)
	waves.set_shader_parameter("shine_color", shine)
	waves.set_shader_parameter("speed", speed)
	material = waves


func _draw() -> void:
	for cell in _cells:
		draw_rect(Rect2(Vector2(cell) * DungeonView.TILE_SIZE, Vector2.ONE * DungeonView.TILE_SIZE), Color.WHITE)
