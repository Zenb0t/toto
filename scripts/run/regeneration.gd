class_name Regeneration
extends RefCounted
## Hurt monsters heal while the hero is away from their map, like Dungeon Crawl's monsters regenerating off
## level: a fixed amount every TICK_SECONDS of run time, worked out on return from how long the hero was gone
## (counted like the other tick clocks, see TickClock). Pure.

## Health points a monster heals per second away (the Tune screen's default).
const DEFAULT_HEALTH_PER_SECOND := 10.0
## Healing comes in steps, one every this many seconds.
const TICK_SECONDS := 1.0


## A monster's health after seconds_away, healing health_per_second, never past its maximum.
static func healed(health: int, max_health: int, seconds_away: float, health_per_second: float) -> int:
	var ticks := TickClock.count_after_each_interval(seconds_away, TICK_SECONDS)
	var gained := roundi(ticks * TICK_SECONDS * maxf(health_per_second, 0.0))
	return clampi(health + gained, 1, max_health)
