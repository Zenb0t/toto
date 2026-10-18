class_name Credits
extends RefCounted
## Everything third-party the game is built with: who made it, under which license, and what we use it for.
## Plain data, so the credits screen only has to show it.


class Entry:
	var name: String
	var author: String
	var license: String
	var url: String
	var used_for: String
	## The folder of assets/ the pack lives in, or "" for what is not a pack of files (the engine, a font).
	var folder: String

	func _init(
			entry_name: String, entry_author: String, entry_license: String, entry_url: String, entry_used_for: String,
			assets_folder := "") -> void:
		name = entry_name
		author = entry_author
		license = entry_license
		url = entry_url
		used_for = entry_used_for
		folder = assets_folder


const CC0 := "CC0 1.0 (public domain)"


## Art first, then what the game runs on.
static func entries() -> Array[Entry]:
	return [
		Entry.new("KayKit Adventurers", "Kay Lousberg", CC0, "https://kaylousberg.itch.io/kaykit-adventurers", "Hero models, their animations and the weapons", "kaykit_adventurers"),
		Entry.new("KayKit Skeletons", "Kay Lousberg", CC0, "https://kaylousberg.itch.io/kaykit-skeletons", "Enemy models and animations", "kaykit_skeletons"),
		Entry.new("KayKit Dungeon Remastered", "Kay Lousberg", CC0, "https://kaylousberg.itch.io/kaykit-dungeon-remastered", "Chests, torches, banners, candles, bottles and coins", "kaykit_dungeon"),
		Entry.new("KayKit Medieval Hexagon Pack", "Kay Lousberg", CC0, "https://kaylousberg.itch.io/kaykit-medieval-hexagon", "The village: houses, inn, church, smithy, market, well, palisade, barrels and crates", "kaykit_medieval_hexagon"),
		Entry.new("Godot Engine", "Juan Linietsky, Ariel Manzur and Godot Engine contributors", "MIT", "https://godotengine.org", "The engine the game runs on"),
		Entry.new("Noto Sans", "Google", "SIL Open Font License 1.1", "https://fonts.google.com/noto/specimen/Noto+Sans", "Godot's default font, used for all the text"),
	]


## What the game was inspired by and the tools it was made with; not code or assets we ship.
static func thanks() -> PackedStringArray:
	return PackedStringArray([
		"Inspired by Dungeon Crawl Stone Soup and Brawl Stars.",
		"Tests run on GUT by Tom \"Butch\" Wesley (MIT), which is not part of the game build.",
	])
