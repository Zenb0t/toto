class_name BurningGround
extends LingeringZone
## Fire left on the ground by a Fireball (like Barley's bottles in Brawl Stars): for a short while it burns
## everyone standing in it, the thrower included, just as the blast did. Ticks at regular intervals, the
## first one half a second after the impact.

const TICK_SECONDS := 0.5
const COLORS := [Color(1.0, 0.3, 0.1), Color(1.0, 0.55, 0.15), Color(1.0, 0.8, 0.3)]
const FLAMES := 9


## `damage` is per tick; the patch lasts `seconds`.
func _init(radius: float, damage: int, seconds: float) -> void:
	super(radius, damage, seconds, TickClock.new(TICK_SECONDS, TICK_SECONDS, TickClock.count_after_each_interval(seconds, TICK_SECONDS)))


func _target_groups() -> Array[StringName]:
	return [Enemy.GROUP, Player.GROUP]


## Flickering tongues of flame over a glow, fading out as the fire dies.
func _draw_zone(left: float) -> void:
	draw_circle(Vector2.ZERO, _radius, Color(COLORS[0], 0.22 * left))
	for i in FLAMES:
		var flicker := 0.5 + 0.5 * sin(_elapsed * 14.0 + i * 2.3)
		var angle := TAU * i / FLAMES + i * 0.7
		var center := Vector2.from_angle(angle) * _radius * (0.2 + 0.55 * fposmod(i * 0.37, 1.0))
		var size := _radius * (0.16 + 0.1 * flicker)
		draw_circle(center, size, Color(COLORS[i % COLORS.size()], (0.3 + 0.3 * flicker) * left))
