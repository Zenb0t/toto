extends GutTest
## The credits must name every third-party pack the game ships, so none goes uncredited.

const ASSET_PACKS_ON_DISK := ["kaykit_adventurers", "kaykit_skeletons", "kaykit_dungeon"]


func _names() -> PackedStringArray:
	var names := PackedStringArray()
	for entry in Credits.entries():
		names.append(entry.name)
	return names


func test_every_kaykit_pack_in_the_assets_folder_is_credited() -> void:
	for pack in ASSET_PACKS_ON_DISK:
		assert_true(DirAccess.dir_exists_absolute("res://assets/%s" % pack), "%s is no longer in assets/" % pack)
	var names := " ".join(_names())
	assert_string_contains(names, "KayKit Adventurers")
	assert_string_contains(names, "KayKit Skeletons")
	assert_string_contains(names, "KayKit Dungeon")


func test_the_engine_is_credited() -> void:
	assert_has(_names(), "Godot Engine")


func test_every_entry_tells_who_made_it_under_which_license_and_where_to_find_it() -> void:
	for entry in Credits.entries():
		assert_ne(entry.author, "", "%s has no author" % entry.name)
		assert_ne(entry.license, "", "%s has no license" % entry.name)
		assert_ne(entry.used_for, "", "%s says nothing about its use" % entry.name)
		assert_true(entry.url.begins_with("https://"), "%s has no link" % entry.name)
