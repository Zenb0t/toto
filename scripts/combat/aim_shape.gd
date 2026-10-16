class_name AimShape
extends RefCounted
## What an ability's aim preview looks like: a line (optionally ending in a blast circle),
## a cone for melee arcs, a fan of lines for spreads, or a lob whose landing spot follows the drag distance.

enum Kind { LINE, CONE, FAN, LOB }

var kind := Kind.LINE
var length := 0.0
var spread_degrees := 0.0
var count := 1
var end_radius := 0.0


static func line(line_length: float, blast_radius := 0.0) -> AimShape:
	var shape := AimShape.new()
	shape.length = line_length
	shape.end_radius = blast_radius
	return shape


static func cone(reach: float, arc_degrees: float) -> AimShape:
	var shape := AimShape.new()
	shape.kind = Kind.CONE
	shape.length = reach
	shape.spread_degrees = arc_degrees
	return shape


## length is the farthest throw; the preview lands where the weapon's aim_distance() puts it.
static func lob(max_range: float, blast_radius: float) -> AimShape:
	var shape := AimShape.new()
	shape.kind = Kind.LOB
	shape.length = max_range
	shape.end_radius = blast_radius
	return shape


static func fan(line_length: float, spread: float, lines: int) -> AimShape:
	var shape := AimShape.new()
	shape.kind = Kind.FAN
	shape.length = line_length
	shape.spread_degrees = spread
	shape.count = lines
	return shape
