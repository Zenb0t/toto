class_name DeathBurst
extends Node3D
## A defeated monster bursts into a spray of chunks in its colour, which fly up, fall and shrink away.
## Hand-made rather than a particle system: a few boxes, which every renderer draws the same.

const CHUNKS := 12
const SECONDS := 0.7
const CHUNK_SIZE := 0.22
const GRAVITY := 14.0
const SPEED_MIN := 2.5
const SPEED_MAX := 4.5

var _chunks: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _elapsed := 0.0


## size: the monster's size (see Monster.size); big monsters burst bigger.
func _init(color: Color, at: Vector3, size := 1.0) -> void:
	position = at + Vector3(0, 0.5 * size, 0)
	var mesh := ModelParts.box(Vector3.ONE * CHUNK_SIZE * size)
	for i in CHUNKS:
		var chunk := ModelParts.part(mesh, color)
		add_child(chunk)
		_chunks.append(chunk)
		var outward := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
		var direction := (outward + Vector3.UP * randf_range(0.6, 1.4)).normalized()
		_velocities.append(direction * randf_range(SPEED_MIN, SPEED_MAX) * size)


func _process(delta: float) -> void:
	_elapsed += delta
	var shrink := clampf(1.0 - _elapsed / SECONDS, 0.01, 1.0)
	for i in _chunks.size():
		_velocities[i].y -= GRAVITY * delta
		_chunks[i].position += _velocities[i] * delta
		_chunks[i].rotation += Vector3(7.0, 5.0, 3.0) * delta
		_chunks[i].scale = Vector3.ONE * shrink
	if _elapsed >= SECONDS:
		queue_free()
