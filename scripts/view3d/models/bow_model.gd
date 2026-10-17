class_name BowModel
extends RefCounted
## A bow for the hand, built from plain parts (the KayKit pack has none): a wooden arc and a string, grip at the
## origin. In a character's hand the y axis points forward (a sword's blade does) and x is up, so the limbs run
## along x and the arc bows out forward along y, with the string on the archer's side.

const LIMB_COLOR := Color(0.55, 0.36, 0.18)
const STRING_COLOR := Color(0.92, 0.9, 0.8)
## How far the tips of the bow reach above and below the grip, and how far the arc bows out in front of the grip.
const HALF_HEIGHT := 0.55
const BOW_DEPTH := 0.2
const SEGMENTS := 8
const LIMB_THICKNESS := 0.05
const STRING_THICKNESS := 0.012


static func build() -> Node3D:
	var bow := Node3D.new()
	var previous := _point(-1.0)
	for index in range(1, SEGMENTS + 1):
		var next := _point(-1.0 + 2.0 * index / SEGMENTS)
		bow.add_child(_bar(previous, next, LIMB_THICKNESS, LIMB_COLOR))
		previous = next
	bow.add_child(_bar(_point(-1.0), _point(1.0), STRING_THICKNESS, STRING_COLOR))
	return bow


## A point along the arc: along is -1 (lower tip) to 1 (upper tip). The grip (0) bows furthest out.
static func _point(along: float) -> Vector3:
	return Vector3(along * HALF_HEIGHT, -BOW_DEPTH * along * along, 0.0)


static func _bar(from: Vector3, to: Vector3, thickness: float, color: Color) -> MeshInstance3D:
	var offset := to - from
	var bar := ModelParts.part(ModelParts.box(Vector3(thickness, thickness, offset.length())), color)
	bar.position = (from + to) / 2.0
	bar.look_at_from_position(bar.position, to, Vector3.FORWARD)
	return bar
