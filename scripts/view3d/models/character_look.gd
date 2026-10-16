class_name CharacterLook
extends RefCounted
## What a character looks like in the 3D view, as plain data: which KayKit model (Adventurers or Skeletons,
## CC0, by Kay Lousberg; see assets/), the colour of its skin, how it is stretched, and per weapon,
## what it holds and how it swings. Races without a model of their own borrow one (an orc is a green
## barbarian, a dwarf a short, stocky one) until real ones arrive.

const MODELS_PATH := "res://assets/kaykit_adventurers/%s.glb"
const UNDEAD_MODELS_PATH := "res://assets/kaykit_skeletons/%s.glb"
const WEAPONS_PATH := "res://assets/kaykit_adventurers/weapons/%s.gltf"
## The model whose animations every character shares (they all use the same skeleton).
const ANIMATED_MODEL := "Knight"
const NO_TINT := Color.WHITE

## The model's name: Knight, Barbarian, Mage, Rogue, Rogue_Hooded (adventurers), or Skeleton_Minion,
## Skeleton_Warrior, Skeleton_Rogue, Skeleton_Mage (the undead).
var model := ANIMATED_MODEL
## Multiplies the colour of the skin (head and arms), so a goblin is green but keeps its clothes.
var skin_tint := NO_TINT
## Stretch on top of the monster's size: a dwarf is short and broad.
var stretch := Vector3.ONE
## Whether the model keeps its hat or helmet. Orcs and ogres go bareheaded, so their skin shows.
var wears_hat := true


func _init(model_name: String, tint := NO_TINT, body_stretch := Vector3.ONE, hat := true) -> void:
	model = model_name
	skin_tint = tint
	stretch = body_stretch
	wears_hat = hat


func model_path() -> String:
	return (UNDEAD_MODELS_PATH if model.begins_with("Skeleton_") else MODELS_PATH) % model


static func hero() -> CharacterLook:
	return CharacterLook.new("Knight")


static func of_monster(monster: Monster) -> CharacterLook:
	match monster.race:
		"kobold":
			return CharacterLook.new("Rogue_Hooded", Color(0.85, 0.6, 0.4))
		"goblin":
			return CharacterLook.new("Rogue", Color(0.55, 0.85, 0.4))
		"orc":
			if is_caster(monster.weapon_id):
				return CharacterLook.new("Mage", Color(0.5, 0.8, 0.45))
			return CharacterLook.new("Barbarian", Color(0.5, 0.8, 0.45), Vector3.ONE, false)
		"dwarf":
			return CharacterLook.new("Barbarian", Color(1.0, 0.85, 0.75), Vector3(1.15, 0.78, 1.15))
		"ogre":
			return CharacterLook.new("Barbarian", Color(0.95, 0.85, 0.55), Vector3.ONE, false)
		"elf":
			return CharacterLook.new("Mage", Color(0.7, 0.75, 1.0))
		"undead":
			match monster.weapon_id:
				"battleaxe":
					return CharacterLook.new("Skeleton_Warrior")
				"crossbow":
					return CharacterLook.new("Skeleton_Rogue")
			return CharacterLook.new("Skeleton_Mage" if is_caster(monster.weapon_id) else "Skeleton_Minion")
	# Humans dress for their weapon.
	if is_caster(monster.weapon_id):
		return CharacterLook.new("Mage")
	return CharacterLook.new("Rogue" if monster.weapon_id == "crossbow" else "Rogue_Hooded")


## Weapons that are spells, cast from a wand, a staff or a book.
static func is_caster(weapon_id: String) -> bool:
	return weapon_id in ["wand", "fireball", "lightning_bolt", "mephitic_cloud"]


## The model in hand for a weapon.
static func weapon_model(weapon_id: String) -> String:
	match weapon_id:
		"sword":
			return "sword_1handed"
		"battleaxe":
			return "axe_2handed"
		"crossbow":
			return "crossbow_1handed"
		"fireball":
			return "staff"
		"mephitic_cloud":
			return "spellbook_open"
	return "wand"


## The animation of one attack with a weapon.
static func attack_animation(weapon_id: String) -> String:
	match weapon_id:
		"sword":
			return "1H_Melee_Attack_Slice_Horizontal"
		"battleaxe":
			return "2H_Melee_Attack_Slice"
		"crossbow":
			return "1H_Ranged_Shoot"
	return "Spellcast_Shoot"


## The animation of using a utility: a dodge for the quick moves, a guard for the shield, a cast for spells.
static func utility_animation(utility_id: String) -> String:
	match utility_id:
		"dash", "blink":
			return "Dodge_Forward"
		"shield":
			return "Block"
	return "Spellcast_Raise"
