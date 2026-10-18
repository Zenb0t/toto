class_name Branch
extends RefCounted
## A part of the dungeon with a character of its own, like Dungeon Crawl's branches: the descent is the crypt
## (the others wait for later ideas), with its own kind of rooms (built or natural caves), its own set pieces (vaults), the
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
## A line on arriving, the way Dungeon Crawl greets a new branch.
var greeting := ""
## Open ground under the sky rather than rooms and corridors: named "the plains", not "floor n".
var outdoors := false
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


## Every branch, in the order the descent once went through them.
static func all() -> Array[Branch]:
	var branches: Array[Branch] = [
		Branch.new("dungeon", "Dungeon", "D", 0.15,
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
	var greetings := [
		"Somewhere below lies the way out.",
		"It smells of damp earth and fur.",
		"Pickaxes ring somewhere in the dark.",
		"Something stirs in the tombs.",
		"Heat rises from far below.",
	]
	for i in branches.size():
		branches[i].greeting = greetings[i]
	return branches


## The crypt: the branch every level of the descent is in. The others stay in code for later ideas.
static func crypt() -> Branch:
	for each in all():
		if each.id == "crypt":
			return each
	push_error("No crypt branch")
	return all()[0]


## The branch the nth entry of all() gives a floor (the last one for anything deeper): how the descent once
## went through every branch, one per floor.
static func for_floor(floor_number: int) -> Branch:
	var branches := all()
	return branches[clampi(floor_number - 1, 0, branches.size() - 1)]


## The plains: the centre quadrant, where a run starts. Not a floor of the descent, so it is not in all().
static func plains() -> Branch:
	var branch := Branch.new("plains", "plains", "Plains", 0.0, [], [], BranchLook.plains())
	branch.greeting = "Grass and wind. Somewhere out here, a way down."
	branch.outdoors = true
	return branch
