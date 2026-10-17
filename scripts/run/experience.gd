class_name Experience
extends RefCounted
## Like Dungeon Crawl's experience levels (or Brawl Stars' power cubes): defeating monsters makes the hero
## tougher. Each kill is worth points; every level needs more points than the one before. Pure.

const MAX_LEVEL := 10
## Going from level n to n + 1 takes n times this many points.
const POINTS_PER_LEVEL := 5
## Extra maximum health for every level above the first.
const HEALTH_PER_LEVEL := 2

var points := 0


func _init(starting_points := 0) -> void:
	points = starting_points


func level() -> int:
	var reached := 1
	while reached < MAX_LEVEL and points >= points_for(reached + 1):
		reached += 1
	return reached


## Adds points and returns how many levels they brought (0 most of the time).
func gain(amount: int) -> int:
	var before := level()
	points += maxi(amount, 0)
	return level() - before


## How far the hero is toward the next level, 0..1 (1 at the top level).
func progress() -> float:
	var current := level()
	if current == MAX_LEVEL:
		return 1.0
	var start := points_for(current)
	return float(points - start) / (points_for(current + 1) - start)


## The points needed to reach a level.
static func points_for(target_level: int) -> int:
	return POINTS_PER_LEVEL * target_level * (target_level - 1) / 2


## The extra maximum health a level brings, on top of the hero's own.
static func bonus_health(at_level: int) -> int:
	return (at_level - 1) * HEALTH_PER_LEVEL
