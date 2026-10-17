class_name Monster
extends RefCounted
## A kind of enemy, like Dungeon Crawl's monsters: a race with its own toughness, pace and build, carrying
## one of the weapons the player can find (the weapon decides how it fights; see EnemyTactics). Plain data.

## Stable identifier.
var id := ""
var display_name := ""
## Its symbol in the map format (see DungeonMapParser).
var letter := ""
var weapon_id := ""
var max_health := 3
## How fast it moves, relative to the tuned enemy speed.
var speed_multiplier := 1.0
## How big it is, relative to an ordinary enemy: its body (what attacks hit) and its model.
var size := 1.0
## Extra damage on every attack: big monsters hit hard.
var damage_bonus := 0
## Its people (kobold, goblin, human, orc, dwarf, ogre): shared looks, and later shared traits.
var race := ""
## The colour of its race.
var color := Color.WHITE


func _init(
		monster_id: String, name: String, symbol: String, weapon: String, health: int, speed: float,
		body_size: float, extra_damage: int, people: String, race_color: Color) -> void:
	id = monster_id
	display_name = name
	letter = symbol
	weapon_id = weapon
	max_health = health
	speed_multiplier = speed
	size = body_size
	damage_bonus = extra_damage
	race = people
	color = race_color


## "a kobold", "an orc wizard": how a message names one of them.
static func with_article(name: String) -> String:
	var article := "an" if name.to_lower()[0] in ["a", "e", "i", "o", "u"] else "a"
	return "%s %s" % [article, name.to_lower()]
