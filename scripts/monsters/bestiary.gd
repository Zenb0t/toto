class_name Bestiary
extends RefCounted
## Every monster in the dungeon. Like Dungeon Crawl's early floors: quick, weak kobolds and goblins first,
## humans and their necromancers, then orcs and their wizards, slow and sturdy dwarves, deep elf mages
## casting lightning, the restless undead, and ogres swinging battleaxes.

const KOBOLD_COLOR := Color(0.78, 0.55, 0.3)
const GOBLIN_COLOR := Color(0.5, 0.75, 0.3)
const HUMAN_COLOR := Color(0.9, 0.62, 0.5)
const ORC_COLOR := Color(0.32, 0.55, 0.32)
const ORC_WIZARD_COLOR := Color(0.55, 0.4, 0.75)
const DWARF_COLOR := Color(0.72, 0.42, 0.25)
const OGRE_COLOR := Color(0.7, 0.66, 0.45)
const NECROMANCER_COLOR := Color(0.55, 0.5, 0.6)
const DEEP_ELF_COLOR := Color(0.55, 0.6, 0.9)
const UNDEAD_COLOR := Color(0.85, 0.85, 0.78)


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
		Monster.new("necromancer", "Necromancer", "n", "mephitic_cloud", 4, 0.95, 1.0, 0, "human", NECROMANCER_COLOR),
		Monster.new("orc", "Orc", "o", "sword", 5, 1.0, 1.15, 0, "orc", ORC_COLOR),
		Monster.new("orc_wizard", "Orc wizard", "W", "fireball", 4, 0.95, 1.1, 0, "orc", ORC_WIZARD_COLOR),
		Monster.new("dwarf", "Dwarf", "d", "crossbow", 8, 0.7, 0.95, 0, "dwarf", DWARF_COLOR),
		Monster.new("deep_elf_mage", "Deep elf mage", "e", "lightning_bolt", 5, 1.05, 0.95, 0, "elf", DEEP_ELF_COLOR),
		Monster.new("skeleton", "Skeleton", "z", "sword", 4, 0.9, 1.0, 0, "undead", UNDEAD_COLOR),
		Monster.new("skeleton_archer", "Skeleton archer", "x", "crossbow", 4, 0.9, 1.0, 0, "undead", UNDEAD_COLOR),
		Monster.new("skeletal_mage", "Skeletal mage", "m", "mephitic_cloud", 5, 0.9, 1.0, 0, "undead", UNDEAD_COLOR),
		Monster.new("skeleton_warrior", "Skeleton warrior", "Z", "battleaxe", 7, 0.85, 1.1, 0, "undead", UNDEAD_COLOR),
		Monster.new("ogre", "Ogre", "O", "battleaxe", 14, 0.6, 1.6, 1, "ogre", OGRE_COLOR),
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
