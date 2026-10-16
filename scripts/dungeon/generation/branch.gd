class_name Branch
extends RefCounted
## A part of the dungeon with a character of its own, like Dungeon Crawl's branches: each floor of the
## descent is one, with its own kind of rooms (built or natural caves), its own set pieces (vaults), the
## monsters that live there and its own look (see BranchLook). Plain data.

## Stable identifier.
var id := ""
## Its name, as in "the Orcish Mines".
var display_name := ""
## Short name for the HUD, the way Dungeon Crawl writes places ("D", "Lair", "Orc"...).
var abbreviation := ""
## The share of rooms (other than the start) that are natural caves rather than built rooms.
var cave_share := 0.0
## The vaults that may appear here (names in Vaults.DESIGNS).
var vaults: Array[String] = []
## Monster letters (see Bestiary) that live here: added, twice, to every room's pool.
var favoured: Array[String] = []
## Whether its caves have puddles of shallow water (see DungeonGenerator).
var puddles := false
var look: BranchLook


func _init(
		branch_id: String, name: String, short_name: String, caves: float, vault_names: Array[String],
		monsters: Array[String], branch_look: BranchLook, wet := false) -> void:
	id = branch_id
	display_name = name
	abbreviation = short_name
	cave_share = caves
	vaults = vault_names
	favoured = monsters
	look = branch_look
	puddles = wet


## Every branch, in the order the descent goes through them: one per floor.
static func all() -> Array[Branch]:
	return [
		Branch.new("dungeon", "Dungeon", "D", 0.0,
			["pillared_hall", "statue_gallery", "treasure_closet", "moat_island"], [], BranchLook.dungeon()),
		Branch.new("lair", "Lair", "Lair", 0.75,
			["lake", "pool", "moat_island"], ["g", "a", "k"], BranchLook.lair(), true),
		Branch.new("orcish_mines", "Orcish Mines", "Orc", 0.85,
			["rubble_cavern", "rubble_cavern", "ember_corners", "lava_river"], ["o", "o", "W"], BranchLook.mines()),
		Branch.new("crypt", "Crypt", "Crypt", 0.0,
			["catacomb", "catacomb", "statue_gallery", "treasure_closet"], ["z", "z", "x", "m", "Z"], BranchLook.crypt()),
		Branch.new("depths", "Depths", "Depths", 0.3,
			["lava_lake", "lava_lake", "ember_corners", "pillared_hall"], ["e", "O", "d", "W"], BranchLook.depths()),
	]


## The branch a floor of the descent is in (the last one for anything deeper).
static func for_floor(floor_number: int) -> Branch:
	var branches := all()
	return branches[clampi(floor_number - 1, 0, branches.size() - 1)]
