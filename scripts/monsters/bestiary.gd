class_name Bestiary
extends RefCounted
## Every monster in the dungeon. Like Dungeon Crawl's early floors: quick, weak kobolds and goblins first,
## humans, then orcs and their wizards, slow and sturdy dwarves, and ogres that hit very hard.

const KOBOLD_COLOR := Color(0.78, 0.55, 0.3)
const GOBLIN_COLOR := Color(0.5, 0.75, 0.3)
const HUMAN_COLOR := Color(0.9, 0.62, 0.5)
const ORC_COLOR := Color(0.32, 0.55, 0.32)
const ORC_WIZARD_COLOR := Color(0.55, 0.4, 0.75)
const DWARF_COLOR := Color(0.72, 0.42, 0.25)
const OGRE_COLOR := Color(0.7, 0.66, 0.45)


static func all() -> Array[Monster]:
	return [
		# id, name, map letter, weapon, health, speed, size, extra damage, race, colour
		Monster.new("kobold", "Kobold", "k", "sword", 2, 1.25, 0.8, 0, "kobold", KOBOLD_COLOR),
		Monster.new("goblin", "Goblin", "g", "wand", 2, 1.1, 0.85, 0, "goblin", GOBLIN_COLOR),
		Monster.new("goblin_archer", "Goblin archer", "a", "crossbow", 2, 1.1, 0.85, 0, "goblin", GOBLIN_COLOR),
		Monster.new("bandit", "Bandit", "s", "sword", 3, 1.0, 1.0, 0, "human", HUMAN_COLOR),
		Monster.new("apprentice", "Apprentice", "w", "wand", 3, 1.0, 1.0, 0, "human", HUMAN_COLOR),
		Monster.new("crossbowman", "Crossbowman", "c", "crossbow", 3, 1.0, 1.0, 0, "human", HUMAN_COLOR),
		Monster.new("pyromancer", "Pyromancer", "f", "fireball", 3, 1.0, 1.0, 0, "human", HUMAN_COLOR),
		Monster.new("orc", "Orc", "o", "sword", 5, 1.0, 1.15, 0, "orc", ORC_COLOR),
		Monster.new("orc_wizard", "Orc wizard", "W", "fireball", 4, 0.95, 1.1, 0, "orc", ORC_WIZARD_COLOR),
		Monster.new("dwarf", "Dwarf", "d", "crossbow", 8, 0.7, 0.95, 0, "dwarf", DWARF_COLOR),
		Monster.new("ogre", "Ogre", "O", "sword", 14, 0.6, 1.6, 2, "ogre", OGRE_COLOR),
	]


## Every monster letter the map format knows.
static func letters() -> Array[String]:
	var result: Array[String] = []
	for monster in all():
		result.append(monster.letter)
	return result


## The monster a map letter stands for, or null.
static func by_letter(symbol: String) -> Monster:
	for monster in all():
		if monster.letter == symbol:
			return monster
	return null


## The monster with this id; unknown ids fall back to the bandit, so a stale map can't break a run.
static func by_id(monster_id: String) -> Monster:
	for monster in all():
		if monster.id == monster_id:
			return monster
	return by_letter("s")
