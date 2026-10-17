extends GutTest
## Which button's catch zone a finger landed in.

const LEFT := Vector2(100, 100)
const RIGHT := Vector2(200, 100)


func _centers() -> Array[Vector2]:
	return [LEFT, RIGHT]


func _radii(radius: float) -> Array[float]:
	return [radius, radius]


func test_a_touch_inside_one_zone_belongs_to_it() -> void:
	assert_eq(TouchZones.owner_of(LEFT + Vector2(-30, 0), _centers(), _radii(40)), 0)


func test_a_touch_outside_every_zone_belongs_to_none() -> void:
	assert_eq(TouchZones.owner_of(Vector2(150, 300), _centers(), _radii(40)), TouchZones.NONE)


func test_where_zones_overlap_the_nearest_centre_wins() -> void:
	assert_eq(TouchZones.owner_of(Vector2(160, 100), _centers(), _radii(80)), 1)
	assert_eq(TouchZones.owner_of(Vector2(140, 100), _centers(), _radii(80)), 0)
