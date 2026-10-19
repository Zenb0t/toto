class_name TreeShape
extends RefCounted
## A tree as plain parts: a trunk and a crown of three overlapping balls of leaves, in the tree's own space (its
## foot at the origin, about as tall as a wall). DecorModel builds one tree from it as nodes; ForestView draws
## whole woods from the same parts at once. Pure.

const TRUNK_COLOR := Color(0.38, 0.27, 0.18)
const LEAF_COLORS: Array[Color] = [Color(0.25, 0.5, 0.22), Color(0.32, 0.56, 0.2), Color(0.22, 0.45, 0.3)]
const TRUNK_HEIGHT := 0.6
const TRUNK_TOP_RADIUS := 0.1
const TRUNK_BOTTOM_RADIUS := 0.15
const CROWN_BALLS := 3


## One ball of leaves.
class Ball:
	extends RefCounted
	var center: Vector3
	var radius: float
	var color: Color

	func _init(at: Vector3, size: float, tint: Color) -> void:
		center = at
		radius = size
		color = tint


## The crown of a tree; variant (0..1) picks its green and turns the balls about, so no two trees are alike.
static func crown(variant: float) -> Array[Ball]:
	var leaves := LEAF_COLORS[floori(variant * LEAF_COLORS.size()) % LEAF_COLORS.size()]
	var balls: Array[Ball] = []
	for i in CROWN_BALLS:
		var at := Vector3(cos(i * 2.1 + variant * 5.0) * 0.18, 0.75 + 0.12 * (i % 2), sin(i * 2.1 + variant * 5.0) * 0.18)
		balls.append(Ball.new(at, 0.36 - 0.04 * i, leaves.lightened(0.06 * i)))
	return balls
