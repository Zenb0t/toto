class_name MonstersAround
extends RefCounted
## The rule for whether the hero may rest: no, while any monster on the map is hunting them, or any awake monster
## is within the hero's sight and in line of sight. Sleeping monsters don't count. Shared by every place of rest
## (a campfire now, the inn later). Pure: the game describes each monster as a Nearby and asks check().

## How far the hero can see a monster, in cells, for it to stop them resting.
const DEFAULT_SIGHT_CELLS := 16.0

enum Verdict { CALM, HUNTED, WATCHED }


## What the rule needs to know of one monster.
class Nearby:
	extends RefCounted
	## It is not asleep.
	var awake := true
	## It has noticed the hero and is after them.
	var hunting := false
	## How far it is from the hero, in cells.
	var cells := INF
	## Nothing blocks the view between it and the hero.
	var in_line_of_sight := false

	func _init(is_awake := true, is_hunting := false, cells_away := INF, line_of_sight := false) -> void:
		awake = is_awake
		hunting = is_hunting
		cells = cells_away
		in_line_of_sight = line_of_sight


## Tune keys are "<id>.<field>".
var id := "monsters_around"
var sight_cells := DEFAULT_SIGHT_CELLS


func knobs() -> Array[Knob]:
	return [Knob.new("sight_cells", "Awake monster in sight stops rest (cells)", 4, 40, 1)]


## Whether the hero may rest, given every monster on the map; HUNTED outranks WATCHED.
func check(monsters: Array[Nearby]) -> Verdict:
	var verdict := Verdict.CALM
	for each in monsters:
		if each.hunting:
			return Verdict.HUNTED
		if each.awake and each.in_line_of_sight and each.cells <= sight_cells:
			verdict = Verdict.WATCHED
	return verdict


## What to tell the player of a verdict ("" when they may rest).
static func message(verdict: Verdict) -> String:
	match verdict:
		Verdict.HUNTED:
			return "Can't rest: something is hunting you"
		Verdict.WATCHED:
			return "Can't rest: something is watching"
	return ""
