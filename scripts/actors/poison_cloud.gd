class_name PoisonCloud
extends LingeringZone
## A lingering cloud of poison (Dungeon Crawl's Mephitic Cloud): every foe inside it takes damage at
## intervals until it dissipates. The player's clouds hurt enemies; enemies' clouds hurt the player.

const TICK_SECONDS := 0.6
const COLOR := Color(0.55, 0.85, 0.3)
const PUFFS := 7

var _hurts_player: bool


## The first tick comes first_tick_delay after landing (a grace window to run out), then one every TICK_SECONDS up
## to and including the moment the cloud ends.
func _init(radius: float, damage: int, seconds: float, hurts_player: bool, first_tick_delay := 0.0) -> void:
	var ticks := TickClock.count_from(first_tick_delay, seconds, TICK_SECONDS)
	super(radius, damage, seconds, TickClock.new(first_tick_delay, TICK_SECONDS, ticks))
	_hurts_player = hurts_player


func _target_groups() -> Array[StringName]:
	return [Player.GROUP if _hurts_player else Enemy.GROUP]


## Puffs that drift around the middle and thin out as the cloud dissipates.
func _draw_zone(left: float) -> void:
	draw_circle(Vector2.ZERO, _radius, Color(COLOR, 0.18 * left))
	for i in PUFFS:
		var angle := TAU * i / PUFFS + _elapsed * 0.6
		var center := Vector2.from_angle(angle) * _radius * (0.45 + 0.1 * sin(_elapsed * 2.0 + i))
		draw_circle(center, _radius * 0.42, Color(COLOR, 0.16 * left))
