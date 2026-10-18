class_name EnemyBrain
extends RefCounted
## What an enemy is doing, as a small state machine. It only decides; the Enemy node carries each state out.
##
##   ASLEEP ──┐
##            ├──notices (Awareness)──▶ NOTICING ──after noticing_seconds──▶ HUNT / POSITION
##   WANDER ──┘
##
##   HUNT / POSITION ──gives up (Awareness.gives_up)──▶ CHECK ──reached the last-seen spot──▶ RETURN
##   CHECK / RETURN ──notices the hero again──▶ NOTICING        RETURN ──reached home──▶ WANDER
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
## RETREAT: hurt with no target (the Lich, hurt from a doorway before his arena locks), it withdraws to its
## retreat spot (Senses.can_retreat) and stays there; once it has a target it fights.
## A hunter with a home (Senses.has_home) gives up once it hasn't seen the target for a while or the target is
## far from home. CHECK: walks to the spot it last saw the target. RETURN: walks home, then wanders again. Both
## are awake and out of the fight; they notice the target again within the wander sight radius, as long as the
## target is back within its territory (closer to home than it gives up at).

enum State { IDLE, ASLEEP, WANDER, NOTICING, HUNT, POSITION, WINDUP, RECOVER, CHECK, RETURN, RETREAT }

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
	## It has a home to go back to (it was settled there). Without one it never gives up.
	var has_home := false
	## How far its target is from its home, in cells.
	var target_cells_from_home := 0.0
	## Its home is marked as never giving up.
	var never_gives_up := false
	## It has reached where it was walking to (the last-seen spot while CHECK, home while RETURN), or can't.
	var arrived := false
	## Its weapon is ready, the target is within reach, and its squad gave it the turn to attack.
	var has_turn := false
	## Its weapon is still winding up an attack.
	var winding_up := false
	## It has a retreat spot to withdraw to when hurt while it has no target.
	var can_retreat := false


var recover_seconds := DEFAULT_RECOVER_SECONDS
var noticing_seconds := DEFAULT_NOTICING_SECONDS
## When a calm (asleep, wandering or on its way back) enemy notices its target, and when a hunter gives up.
var awareness := Awareness.new()
var state := State.IDLE
var _recover_left := 0.0
var _noticing_left := 0.0
var _seconds_unseen := 0.0


## A brain that starts in a state; a fresh one is IDLE (it fights as soon as it has a target).
func _init(start := State.IDLE) -> void:
	state = start


## Moves time on and returns the state the enemy is in now.
func update(delta: float, senses: Senses) -> State:
	match state:
		State.ASLEEP, State.WANDER:
			if _retreats(senses):
				state = State.RETREAT
			elif awareness.notices(_cues(senses)):
				_notice()
		State.CHECK, State.RETURN:
			if awareness.notices(_cues(senses)) and awareness.in_territory(senses.target_cells_from_home):
				_notice()
			elif not senses.arrived:
				pass
			elif state == State.CHECK:
				state = State.RETURN
			else:
				state = State.WANDER
		State.NOTICING:
			_noticing_left -= delta
			if _noticing_left <= 0.0:
				state = _seeking(senses) if senses.has_target else State.IDLE
		State.RETREAT:
			if senses.has_target:
				state = _seeking(senses)
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
			_seconds_unseen = 0.0 if senses.sees_target else _seconds_unseen + delta
			if _retreats(senses):
				state = State.RETREAT
			elif not senses.has_target:
				state = State.IDLE
			elif senses.has_home and awareness.gives_up(_chase(senses)):
				state = State.CHECK
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


## It has noticed its target and is after it (noticing, hunting, in position, attacking or stepping aside), as
## opposed to asleep, wandering or giving up.
func is_hunting() -> bool:
	return state in [State.NOTICING, State.HUNT, State.POSITION, State.WINDUP, State.RECOVER]


func is_asleep() -> bool:
	return state == State.ASLEEP


## Checking or on its way home: it has given up the chase, but is awake and can notice its target again.
func is_giving_up() -> bool:
	return state == State.CHECK or state == State.RETURN


## It is not in the fight: calm, retreating or given up. A squad doesn't count it for turns or flank spots.
func is_out_of_the_fight() -> bool:
	return is_calm() or is_giving_up() or state == State.RETREAT


## How close its target must be for it to matter whether the enemy can see it: its sight while calm, any
## distance once it has noticed.
func notice_range_cells() -> float:
	return awareness.sight_cells(state == State.ASLEEP) if is_out_of_the_fight() else INF


## Hurt with no target and somewhere to hide: it withdraws instead of standing there.
static func _retreats(senses: Senses) -> bool:
	return senses.can_retreat and senses.hurt and not senses.has_target


func _notice() -> void:
	state = State.NOTICING
	_noticing_left = noticing_seconds
	_seconds_unseen = 0.0


func _chase(senses: Senses) -> Awareness.Chase:
	var chase := Awareness.Chase.new()
	chase.seconds_unseen = _seconds_unseen
	chase.hero_cells_from_home = senses.target_cells_from_home
	chase.never_gives_up = senses.never_gives_up
	return chase


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
