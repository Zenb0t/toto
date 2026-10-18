class_name EnemyBrain
extends RefCounted
## What an enemy is doing, as a small state machine. It only decides; the Enemy node carries each state out.
##
##   ASLEEP ──┐
##            ├──notices (Awareness)──▶ NOTICING ──after noticing_seconds──▶ HUNT / POSITION
##   WANDER ──┘
##
##   IDLE ──target──▶ HUNT ◀──lost sight / regained──▶ POSITION
##                      │                                  │
##                      └──────── its turn to attack ──────┘
##                                       ▼
##                                    WINDUP ──attack over──▶ RECOVER ──after recover_seconds──▶ HUNT / POSITION
##
## ASLEEP: sleeps at home. WANDER: strolls slowly about its home. Both are calm: they only leave once the
## enemy notices its target (see Awareness). NOTICING: has just noticed it, and stands still for a moment
## before going after it. IDLE: awake, but no target. HUNT: can't see the target, walks around walls to find
## it. POSITION: sees it, keeps to its weapon's distance at its flank spot. WINDUP: stands still and telegraphs
## the attack. RECOVER: steps aside for a moment before looking for its next turn.

enum State { IDLE, ASLEEP, WANDER, NOTICING, HUNT, POSITION, WINDUP, RECOVER }

## How long an enemy steps aside after an attack before it may attack again.
const DEFAULT_RECOVER_SECONDS := 0.35
## How long an enemy stands still, showing it has noticed its target, before it goes after it.
const DEFAULT_NOTICING_SECONDS := 0.4


## What the enemy knows this step, gathered by the Enemy node.
class Senses:
	var has_target := false
	## Nothing blocks the view between it and its target.
	var sees_target := false
	## How far its target is, in cells (INF without one).
	var target_cells := INF
	## It took damage since the last step.
	var hurt := false
	## It heard a noise or a shout since the last step.
	var alerted := false
	## Its weapon is ready, the target is within reach, and its squad gave it the turn to attack.
	var has_turn := false
	## Its weapon is still winding up an attack.
	var winding_up := false


var recover_seconds := DEFAULT_RECOVER_SECONDS
var noticing_seconds := DEFAULT_NOTICING_SECONDS
## When a calm (asleep or wandering) enemy notices its target.
var awareness := Awareness.new()
var state := State.IDLE
var _recover_left := 0.0
var _noticing_left := 0.0


## A brain that starts in a state; a fresh one is IDLE (it fights as soon as it has a target).
func _init(start := State.IDLE) -> void:
	state = start


## Moves time on and returns the state the enemy is in now.
func update(delta: float, senses: Senses) -> State:
	match state:
		State.ASLEEP, State.WANDER:
			if awareness.notices(_cues(senses)):
				state = State.NOTICING
				_noticing_left = noticing_seconds
		State.NOTICING:
			_noticing_left -= delta
			if _noticing_left <= 0.0:
				state = _seeking(senses) if senses.has_target else State.IDLE
		State.WINDUP:
			if not senses.winding_up:
				state = State.RECOVER
				_recover_left = recover_seconds
		State.RECOVER:
			_recover_left -= delta
			if not senses.has_target:
				state = State.IDLE
			elif _recover_left <= 0.0:
				state = _seeking(senses)
		_:
			if not senses.has_target:
				state = State.IDLE
			elif senses.has_turn:
				state = State.WINDUP
			else:
				state = _seeking(senses)
	return state


## Whether it may take a turn to attack in its current state.
func is_looking_for_a_turn() -> bool:
	return state == State.HUNT or state == State.POSITION


## Asleep or wandering: it hasn't noticed its target.
func is_calm() -> bool:
	return state == State.ASLEEP or state == State.WANDER


## How close its target must be for it to matter whether the enemy can see it: its sight while calm, any
## distance once it has noticed.
func notice_range_cells() -> float:
	return awareness.sight_cells(state == State.ASLEEP) if is_calm() else INF


func _cues(senses: Senses) -> Awareness.Cues:
	var cues := Awareness.Cues.new()
	cues.asleep = state == State.ASLEEP
	cues.hero_cells = senses.target_cells
	cues.hero_in_line_of_sight = senses.has_target and senses.sees_target
	cues.hurt = senses.hurt
	cues.alerted = senses.alerted
	return cues


static func _seeking(senses: Senses) -> State:
	return State.POSITION if senses.sees_target else State.HUNT
