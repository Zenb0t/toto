class_name SpellPicker
extends RefCounted
## Which spell the Lich casts next, as a small rule like EnemyTactics: one spell at a time, with a pause between,
## each telegraphed by whoever casts it. It only decides; the Enemy carries the spell out and tells it when the
## cast starts (begin) and is over (end).
##
##   Summon Undead whenever fewer skeletons are alive than the summon cap;
##   otherwise Mephitic Cloud, Mephitic Cloud, Bone Spray, round and round.
##
## Below phase_two_health_share of his health (phase two) the pause is shorter and the cap goes up by
## phase_two_cap_bonus, never past MAX_SUMMON_CAP. A spell the caster doesn't know (known) is skipped: one that
## knows only the Cloud and Bone Spray casts Cloud, Cloud, Bone Spray round and round; the Lich knows Summon Undead
## too, which comes first whenever the cap is not full and there is ground to raise a skeleton on.
## Bone Spray is the rarest spell: once per clouds_per_spray + 1 casts; the rule has no dice.

enum Spell { NONE, CLOUD, BONE_SPRAY, SUMMON }

const DEFAULT_PAUSE_SECONDS := 1.5
const DEFAULT_PHASE_TWO_PAUSE_SECONDS := 0.8
const DEFAULT_PHASE_TWO_HEALTH_SHARE := 0.5
const DEFAULT_SUMMON_CAP := 5
const DEFAULT_PHASE_TWO_CAP_BONUS := 2
## The summon cap never passes this, however it is tuned.
const MAX_SUMMON_CAP := 10
const DEFAULT_CLOUDS_PER_SPRAY := 2


## What the caster is facing this moment.
class Situation:
	extends RefCounted
	## Skeletons raised by Summon Undead that are still alive.
	var living_skeletons := 0
	## His health as a share of his maximum (1 = untouched).
	var health_share := 1.0
	## Whether Summon Undead would find ground to raise a skeleton on (with the hero too close there is none).
	var room_to_summon := true

	func _init(skeletons := 0, health := 1.0, room := true) -> void:
		living_skeletons = skeletons
		health_share = health
		room_to_summon = room


## Stable identifier; also the prefix of the tuning keys.
var id := "lich_spells"
## The pause between the end of one spell and the start of the next, in seconds.
var pause_seconds := DEFAULT_PAUSE_SECONDS
var phase_two_pause_seconds := DEFAULT_PHASE_TWO_PAUSE_SECONDS
var phase_two_health_share := DEFAULT_PHASE_TWO_HEALTH_SHARE
var summon_cap := DEFAULT_SUMMON_CAP
var phase_two_cap_bonus := DEFAULT_PHASE_TWO_CAP_BONUS
## How many Clouds he casts between two Bone Sprays.
var clouds_per_spray := DEFAULT_CLOUDS_PER_SPRAY
## The spells he knows. The Cloud is always among them.
var known: Array[Spell] = [Spell.CLOUD, Spell.BONE_SPRAY, Spell.SUMMON]

var _casting := false
## Seconds of pause left; he starts ready.
var _pause_left := 0.0
var _clouds_since_spray := 0


func knobs() -> Array[Knob]:
	return [
		Knob.new("pause_seconds", "Pause between spells (s)", 0.0, 6.0, 0.1),
		Knob.new("phase_two_pause_seconds", "Pause when angry (s)", 0.0, 6.0, 0.1),
		Knob.new("phase_two_health_share", "Angry below (share of health)", 0.0, 1.0, 0.05),
		Knob.new("summon_cap", "Summon cap (skeletons)", 1, MAX_SUMMON_CAP, 1),
		Knob.new("phase_two_cap_bonus", "Extra summon cap when angry", 0, MAX_SUMMON_CAP, 1),
		Knob.new("clouds_per_spray", "Clouds between Bone Sprays", 1, 6, 1),
	]


## Moves the pause on. The pause only runs while no spell is being cast.
func advance(delta: float) -> void:
	if not _casting:
		_pause_left = maxf(_pause_left - delta, 0.0)


## Whether a spell may start now: none is being cast and the pause is over.
func is_ready() -> bool:
	return not _casting and _pause_left <= 0.0


func is_casting() -> bool:
	return _casting


## The spell to cast next, or NONE while one is being cast or the pause lasts. Changes nothing: begin() starts it.
func pick(situation: Situation) -> Spell:
	if not is_ready():
		return Spell.NONE
	if Spell.SUMMON in known and situation.room_to_summon and situation.living_skeletons < cap(situation.health_share):
		return Spell.SUMMON
	if Spell.BONE_SPRAY in known and _clouds_since_spray >= clouds_per_spray:
		return Spell.BONE_SPRAY
	return Spell.CLOUD


## A spell starts. Ignored for NONE and while another is being cast: there is only ever one.
func begin(spell: Spell) -> void:
	if spell == Spell.NONE or _casting:
		return
	_casting = true
	match spell:
		Spell.CLOUD:
			_clouds_since_spray += 1
		Spell.BONE_SPRAY:
			_clouds_since_spray = 0


## The spell is over: the pause before the next one starts, shorter in phase two.
func end(health_share: float) -> void:
	if not _casting:
		return
	_casting = false
	_pause_left = phase_two_pause_seconds if is_phase_two(health_share) else pause_seconds


## Whether he is angry: below phase_two_health_share of his health.
func is_phase_two(health_share: float) -> bool:
	return health_share < phase_two_health_share


## The most skeletons that may be alive at once now: the base cap, plus the bonus in phase two, clamped.
func cap(health_share: float) -> int:
	var raised := summon_cap + (phase_two_cap_bonus if is_phase_two(health_share) else 0)
	return clampi(raised, 0, MAX_SUMMON_CAP)
