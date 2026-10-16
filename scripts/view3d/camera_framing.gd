class_name CameraFraming
extends RefCounted
## Brawl Stars-style framing: a fixed camera that never turns, tilted down at the hero from behind (the
## bottom of the screen), aimed a little past them so more of what is ahead shows.

const DEFAULT_PITCH_DEGREES := 55.0
const DEFAULT_DISTANCE := 17.0
const DEFAULT_FIELD_OF_VIEW := 38.0
const DEFAULT_LOOK_AHEAD := 1.5

## How steeply the camera looks down: 90 is straight down, lower shows more of the walls' faces.
var pitch_degrees := DEFAULT_PITCH_DEGREES
## How far the camera is from the point it looks at, in cells.
var distance := DEFAULT_DISTANCE
## Vertical field of view, in degrees. Narrow keeps the far side of the screen from shrinking much.
var field_of_view := DEFAULT_FIELD_OF_VIEW
## How far ahead (up the screen) of the hero the camera aims, in cells.
var look_ahead := DEFAULT_LOOK_AHEAD


## The point the camera looks at, for a hero standing at focus.
func target(focus: Vector3) -> Vector3:
	return focus + Vector3(0.0, 0.0, -look_ahead)


## Where the camera sits, for a hero standing at focus.
func eye(focus: Vector3) -> Vector3:
	var pitch := deg_to_rad(pitch_degrees)
	return target(focus) + Vector3(0.0, sin(pitch), cos(pitch)) * distance


## The cells between the camera and a hero standing on a cell: the few right in front of them, toward the
## bottom of the screen, where a wall would hide them. Walls there are cut down (see MapView3D).
static func cells_hiding(hero_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in range(1, 3):
		for dx in range(-1, 2):
			cells.append(hero_cell + Vector2i(dx, dy))
	return cells
