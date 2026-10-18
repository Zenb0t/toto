class_name Awareness
extends RefCounted
## When a monster that is asleep or wandering at home notices the hero. No dice: it notices when it can see the
## hero (line of sight) close enough, when it is hurt, or when it hears a noise or a shout.
## Pure rules: the monster gathers the Cues, its EnemyBrain asks notices(). Who hears a sound is decided here too
## (noise_hearers, shout_hearers); the world only tells it where the sound was made and carries out the waking.
## Sound goes through walls: only the distance counts. A monster's band always hears it shout, however far.

## How far, in cells, the hero's attacks and blasts are heard.
const DEFAULT_NOISE_CELLS := 8.0
## How far, in cells, a monster that notices the hero is heard.
const DEFAULT_SHOUT_CELLS := 8.0
## How close the hero must be, in cells, for a sleeping monster to notice them.
const DEFAULT_ASLEEP_SIGHT_CELLS := 4.0
## How close the hero must be, in cells, for a wandering monster to notice them.
const DEFAULT_WANDER_SIGHT_CELLS := 9.0


## What a calm monster has to go on this step.
class Cues:
	## Asleep, or awake and wandering about its home.
	var asleep := true
	## How far the hero is, in cells (INF when there is no hero).
	var hero_cells := INF
	## Nothing blocks the view between it and the hero.
	var hero_in_line_of_sight := false
	## It took damage.
	var hurt := false
	## It heard a noise or a shout.
	var alerted := false


var asleep_sight_cells := DEFAULT_ASLEEP_SIGHT_CELLS
var wander_sight_cells := DEFAULT_WANDER_SIGHT_CELLS
var noise_cells := DEFAULT_NOISE_CELLS
var shout_cells := DEFAULT_SHOUT_CELLS


## How far it can notice the hero from, in cells.
func sight_cells(asleep: bool) -> float:
	return asleep_sight_cells if asleep else wander_sight_cells


## Whether a calm monster notices the hero now.
func notices(cues: Cues) -> bool:
	if cues.hurt or cues.alerted:
		return true
	return cues.hero_in_line_of_sight and cues.hero_cells <= sight_cells(cues.asleep)


## Which of the listeners hear a noise (the hero's attack, a blast) made at origin: their indexes. All in cells.
func noise_hearers(origin: Vector2, listeners: PackedVector2Array) -> Array[int]:
	return _within(noise_cells, origin, listeners)


## Which of the listeners hear the one at index shouter shout (it has noticed the hero): the rest of its band,
## however far, and any other within shout_cells. Their indexes, never the shouter's. Positions in cells; bands
## holds each listener's band.
func shout_hearers(shouter: int, listeners: PackedVector2Array, bands: PackedInt32Array) -> Array[int]:
	var heard: Array[int] = []
	for index in _within(shout_cells, listeners[shouter], listeners):
		if index != shouter:
			heard.append(index)
	for index in listeners.size():
		if index != shouter and bands[index] == bands[shouter] and not heard.has(index):
			heard.append(index)
	heard.sort()
	return heard


func _within(radius: float, origin: Vector2, listeners: PackedVector2Array) -> Array[int]:
	var heard: Array[int] = []
	for index in listeners.size():
		if origin.distance_to(listeners[index]) <= radius:
			heard.append(index)
	return heard
