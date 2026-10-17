class_name PoisonStatus
extends RefCounted
## Poison doesn't stack: a body breathing several clouds takes poison as if it stood in one, at most one tick per
## TICK_SECONDS, from whichever cloud ticks first. Each body that can be poisoned owns one of these and asks it
## before taking a tick; `now` is game time in seconds, given by the caller so the rule stays pure.

const TICK_SECONDS := 0.6
## Ticks of one cloud come TICK_SECONDS apart give or take a frame; this much early still counts as due, so a
## lone cloud is never blocked by its own previous tick.
const TOLERANCE := 0.05

var _last_tick_at := -INF


## Whether a poison tick at `now` goes through. If it does, it is recorded and blocks other clouds' ticks for
## the next TICK_SECONDS.
func try_tick(now: float) -> bool:
	if now - _last_tick_at < TICK_SECONDS - TOLERANCE:
		return false
	_last_tick_at = now
	return true
