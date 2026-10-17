class_name TickClock
extends RefCounted
## When a lingering effect ticks: first after `first_after` seconds, then every `interval`, at most `count`
## times. Feed it the elapsed time each frame and it says how many ticks came due.

## Float slack so a tick due exactly at a frame boundary isn't pushed to the next frame.
const SLACK := 0.0001

var _interval: float
var _count: int
var _next_at: float
var _done := 0
var _elapsed := 0.0


func _init(first_after: float, interval: float, count: int) -> void:
	_next_at = first_after
	_interval = interval
	_count = count


## Ticks at first_after, then every interval, up to and including `seconds` (a 6 s poison cloud whose first tick
## comes at 0.6 s, ticking every 0.6 s: 10).
static func count_from(first_after: float, seconds: float, interval: float) -> int:
	return maxi(floori((seconds - first_after) / interval + SLACK) + 1, 0)


## Ticks at interval, 2 x interval ... up to and including `seconds` (a 1.5 s fire ticking every 0.5 s: 3).
static func count_after_each_interval(seconds: float, interval: float) -> int:
	return maxi(floori(seconds / interval + SLACK), 0)


## Moves time on and returns how many ticks came due meanwhile.
func advance(delta: float) -> int:
	_elapsed += delta
	var due := 0
	while _done < _count and _elapsed + SLACK >= _next_at:
		_done += 1
		_next_at += _interval
		due += 1
	return due
