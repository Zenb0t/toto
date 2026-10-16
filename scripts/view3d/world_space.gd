class_name WorldSpace
extends RefCounted
## Where the 2D game plane sits in the 3D view. The game runs on a flat 2D plane (pixels, y pointing down
## the screen); the 3D view lays that plane on the ground: one map cell is one unit, 2D x is 3D x, 2D y is
## 3D z, and 3D y is height above the floor.

const UNITS_PER_PIXEL := 1.0 / DungeonView.TILE_SIZE


## A point of the 2D plane, lifted height units above the floor.
static func to_3d(point: Vector2, height := 0.0) -> Vector3:
	return Vector3(point.x * UNITS_PER_PIXEL, height, point.y * UNITS_PER_PIXEL)


## A length on the 2D plane, in 3D units.
static func length_to_3d(pixels: float) -> float:
	return pixels * UNITS_PER_PIXEL


## The turn around the vertical axis that points a model's front (Godot's -Z) along a 2D direction.
static func yaw_toward(direction: Vector2) -> float:
	return atan2(-direction.x, -direction.y)
