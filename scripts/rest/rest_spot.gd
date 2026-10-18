class_name RestSpot
extends Node2D
## Carries out a Campfire in the world: stands where the fire is, lets time move on for it while the hero is on its
## map (the game is paused, or the map gone, when not), heals the hero standing in its light, and, once the hero
## rests at it (rest()), ends the healing when they are hit or attack. A hit or an attack ends the rest only at the
## fire the hero rests at, never at another fire burning on the map. The rules are the Campfire's; this only feeds
## it the hero.

var fire: Campfire
var _hero: Player
## The hero lit it to rest (rest()), so their hits and attacks end the healing.
var _rested_at := false


func _init(campfire: Campfire, at: Vector2) -> void:
	fire = campfire
	position = at


## The hero this fire heals and listens to: once they rest at it, a hit or an attack of theirs ends the healing.
func attend(hero: Player) -> void:
	_hero = hero
	hero.health.damaged.connect(func(_amount: int) -> void: _end_rest())
	hero.attack_fired.connect(func(_attacks: Array) -> void: _end_rest())


## The hero lights it to rest. False when it can't be lit (burning or in embers).
func rest() -> bool:
	_rested_at = fire.light()
	return _rested_at


func _end_rest() -> void:
	if _rested_at:
		fire.interrupt()
		_rested_at = false


## How far the hero is from the fire, in cells.
func hero_cells() -> float:
	return global_position.distance_to(_hero.global_position) / DungeonView.TILE_SIZE


## Whether the hero is in the fire's light.
func lights_hero() -> bool:
	return fire.profile.lights(hero_cells())


func _physics_process(delta: float) -> void:
	if _hero == null or _hero.health.is_dead():
		return
	var healed := fire.tick(delta, lights_hero(), _hero.health.current, _hero.health.maximum)
	if healed > 0:
		_hero.health.heal(healed)
