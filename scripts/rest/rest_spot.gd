class_name RestSpot
extends Node2D
## Carries out a Campfire in the world: stands where the fire is, lets time move on for it while the hero is on its
## map (the game is paused, or the map gone, when not), heals the hero standing in its light, and ends the healing
## when the hero is hit or attacks. The rules are the Campfire's; this only feeds it the hero.

var fire: Campfire
var _hero: Player


func _init(campfire: Campfire, at: Vector2) -> void:
	fire = campfire
	position = at


## The hero this fire heals and listens to: a hit or an attack of theirs ends the healing.
func attend(hero: Player) -> void:
	_hero = hero
	hero.health.damaged.connect(func(_amount: int) -> void: fire.interrupt())
	hero.attack_fired.connect(func(_attacks: Array) -> void: fire.interrupt())


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
