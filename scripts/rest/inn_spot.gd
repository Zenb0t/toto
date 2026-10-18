class_name InnSpot
extends Node2D
## Carries out the inn's rest in the world: stands on the inn's doorstep, ticks an InnRest every physics frame, heals
## the hero when it completes, and ends it when the hero is hit. (Moving is read from the hero every frame.) The
## rules are InnRest's; this only feeds it the hero and says how a rest ended.

## A rest ended: completed (the hero was healed) or cancelled (moved, or hit).
signal rest_ended(completed: bool)

var rest: InnRest
var _hero: Player


func _init(inn_rest: InnRest, at: Vector2) -> void:
	rest = inn_rest
	position = at


## The hero this rest heals and listens to: a hit of theirs cancels it.
func attend(hero: Player) -> void:
	_hero = hero
	hero.health.damaged.connect(func(_amount: int) -> void:
		if rest.interrupt():
			rest_ended.emit(false))


## How far the hero is from the doorstep, in cells.
func hero_cells() -> float:
	return global_position.distance_to(_hero.global_position) / DungeonView.TILE_SIZE


func is_within_reach() -> bool:
	return _hero != null and rest.profile.is_within_reach(hero_cells())


func _physics_process(delta: float) -> void:
	if _hero == null or _hero.health.is_dead():
		return
	var step := rest.tick(delta, _hero.is_moving())
	if step == InnRest.Step.COMPLETED:
		_hero.health.heal(rest.heal_for(_hero.health.current, _hero.health.maximum))
		rest_ended.emit(true)
	elif step == InnRest.Step.CANCELLED:
		rest_ended.emit(false)
