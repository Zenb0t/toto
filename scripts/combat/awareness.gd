class_name Awareness
extends RefCounted
## When a monster that is asleep or wandering at home notices the hero. No dice: it notices when it can see the
## hero (line of sight) close enough, when it is hurt, or when its band calls it.
## Pure rules: the monster gathers the Cues, its EnemyBrain asks notices().

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
	## Its band noticed the hero.
	var alerted := false


var asleep_sight_cells := DEFAULT_ASLEEP_SIGHT_CELLS
var wander_sight_cells := DEFAULT_WANDER_SIGHT_CELLS


## How far it can notice the hero from, in cells.
func sight_cells(asleep: bool) -> float:
	return asleep_sight_cells if asleep else wander_sight_cells


## Whether a calm monster notices the hero now.
func notices(cues: Cues) -> bool:
	if cues.hurt or cues.alerted:
		return true
	return cues.hero_in_line_of_sight and cues.hero_cells <= sight_cells(cues.asleep)
