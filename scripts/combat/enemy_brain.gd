class_name EnemyBrain
extends RefCounted
## What an enemy is doing, as a small state machine. It only decides; the Enemy node carries each state out.
##
##   IDLE ──target──▶ HUNT ◀──lost sight / regained──▶ POSITION
##                      │                                  │
##                      └──────── its turn to attack ──────┘
##                                       ▼
##                                    WINDUP ──attack over──▶ RECOVER ──after recover_seconds──▶ HUNT / POSITION
##
## IDLE: no target yet. HUNT: can't see the target, walks around walls to find it. POSITION: sees it, keeps
## to its weapon's distance at its flank spot. WINDUP: stands still and telegraphs the attack. RECOVER: steps
## aside for a moment before looking for its next turn.

enum State { IDLE, HUNT, POSITION, WINDUP, RECOVER }

## How long an enemy steps aside after an attack before it may attack again.
const DEFAULT_RECOVER_SECONDS := 0.35


## What the enemy knows this step, gathered by the Enemy node.
class Senses:
	var has_target := false
	var sees_target := false
	## Its weapon is ready, the target is within reach, and its squad gave it the turn to attack.
	var has_turn := false
	## Its weapon is still winding up an attack.
	var winding_up := false


var recover_seconds := DEFAULT_RECOVER_SECONDS
var state := State.IDLE
var _recover_left := 0.0


## Moves time on and returns the state the enemy is in now.
func update(delta: float, senses: Senses) -> State:
	match state:
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


static func _seeking(senses: Senses) -> State:
	return State.POSITION if senses.sees_target else State.HUNT
