class_name Squad
extends RefCounted
## The enemies of one room fighting as a team: they take turns to attack instead of firing all at once, and
## spread out around their target instead of bunching up.
## Members are named by an id (any int that is unique in the squad, like the enemy's instance id).

## How many members may be winding up an attack at the same time.
const DEFAULT_MAX_ATTACKERS := 2
## The least time between two members starting their attacks, so attacks come one after another.
const DEFAULT_TURN_GAP_SECONDS := 0.35
## The angle, seen from the target, between neighbouring members' spots. Big enough and they surround it.
const DEFAULT_FLANK_SPREAD_DEGREES := 70.0

var max_attackers := DEFAULT_MAX_ATTACKERS
var turn_gap_seconds := DEFAULT_TURN_GAP_SECONDS
var flank_spread_degrees := DEFAULT_FLANK_SPREAD_DEGREES

var _attacking := {}  # member id -> true
var _since_last_turn := INF
var _bearings := {}  # member id -> the angle it last stood at, seen from the target


func tick(delta: float) -> void:
	_since_last_turn += delta


## Asks for a turn to attack. Returns true, and counts the member as attacking, if one is free.
func request_turn(member_id: int) -> bool:
	if _attacking.has(member_id):
		return true
	if _attacking.size() >= max_attackers or _since_last_turn < turn_gap_seconds:
		return false
	_attacking[member_id] = true
	_since_last_turn = 0.0
	return true


func end_turn(member_id: int) -> void:
	_attacking.erase(member_id)


func is_attacking(member_id: int) -> bool:
	return _attacking.has(member_id)


## Tells the squad where a member stands, as the angle (radians) from the target to it.
func report_bearing(member_id: int, bearing: float) -> void:
	_bearings[member_id] = bearing


## A defeated member frees its turn and its spot.
func leave(member_id: int) -> void:
	_attacking.erase(member_id)
	_bearings.erase(member_id)


## The angle, seen from the target, where the member should stand. A member reports its bearing first.
func flank_bearing(member_id: int) -> float:
	var ids := _bearings.keys()
	var index := ids.find(member_id)
	if index == -1:
		return 0.0
	var bearings: Array[float] = []
	for id: int in ids:
		bearings.append(_bearings[id])
	return slot_bearings(bearings, deg_to_rad(flank_spread_degrees))[index]


## Spots around a target for members standing at these bearings (radians): evenly spaced by spread, centred
## on where the group already is, and handed out in the order the members stand, so nobody crosses over.
## The spacing shrinks when the group would wrap all the way round.
static func slot_bearings(bearings: Array[float], spread: float) -> Array[float]:
	var count := bearings.size()
	var slots: Array[float] = []
	slots.resize(count)
	if count == 0:
		return slots
	var centre := _mean_angle(bearings)
	var order := range(count)
	order.sort_custom(func(a: int, b: int) -> bool:
		return angle_difference(centre, bearings[a]) < angle_difference(centre, bearings[b]))
	var spacing := minf(spread, TAU / count)
	for rank in count:
		slots[order[rank]] = centre + (rank - (count - 1) / 2.0) * spacing
	return slots


static func _mean_angle(angles: Array[float]) -> float:
	var sum := Vector2.ZERO
	for angle in angles:
		sum += Vector2.from_angle(angle)
	return sum.angle() if not sum.is_zero_approx() else angles[0]
