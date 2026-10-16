class_name AimShape
extends RefCounted
## What an ability's aim preview looks like: a line (optionally ending in a blast circle),
## a cone for melee arcs, or a fan of lines for spreads.

enum Kind { LINE, CONE, FAN }

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


static func fan(line_length: float, spread: float, lines: int) -> AimShape:
	var shape := AimShape.new()
	shape.kind = Kind.FAN
	shape.length = line_length
	shape.spread_degrees = spread
	shape.count = lines
	return shape
