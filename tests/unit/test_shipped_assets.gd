extends GutTest
## Every file in assets/ ships in the game (and in the phone download), so each one must be used: a model by a script
## or scene that loads it, a texture by a model that wears it (the pack's loose copy of the texture a .glb carries, or
## the file a .gltf points at). Pieces nobody uses get noticed here and removed.
## Each pack's folder must also be credited (see Credits).

const ASSETS := "res://assets"
## Files that come with a pack but are not game content of their own: licenses, the importer's bookkeeping and a
## .gltf's data file.
const NOT_CONTENT_EXTENSIONS := ["import", "uid", "txt", "md", "bin"]
const MODEL_EXTENSIONS := ["glb", "gltf"]

var _code := ""
var _models_by_folder := {}  # folder -> {file name: its bytes, as hexadecimal text}


func before_all() -> void:
	_code = _text_of_all("res://scripts", ["gd"]) + _text_of_all("res://scenes", ["tscn", "gd"])
	for file in _asset_files():
		if file.get_extension() in MODEL_EXTENSIONS:
			var models: Dictionary = _models_by_folder.get_or_add(file.get_base_dir(), {})
			models[file.get_file()] = FileAccess.get_file_as_bytes(file).hex_encode()


func test_every_model_is_loaded_by_the_game() -> void:
	for file in _asset_files():
		if file.get_extension() in MODEL_EXTENSIONS:
			assert_true(_code.contains(file.get_file().get_basename()), "%s is not used by any script or scene" % file)


func test_every_texture_belongs_to_a_model_that_wears_it() -> void:
	for file in _asset_files():
		if file.get_extension() == "png":
			assert_true(_is_worn_by_a_model(file) or _code.contains(file.get_file()), "%s is used by nothing" % file)


func test_every_pack_in_the_assets_folder_has_a_credit() -> void:
	var credited := PackedStringArray()
	for entry in Credits.entries():
		credited.append(entry.folder)
	for pack in DirAccess.get_directories_at(ASSETS):
		assert_has(credited, pack, "assets/%s is not named by any entry of the Credits" % pack)


func test_every_pack_keeps_its_license_beside_its_files() -> void:
	for pack in DirAccess.get_directories_at(ASSETS):
		assert_true(FileAccess.file_exists("%s/%s/LICENSE.txt" % [ASSETS, pack]), "assets/%s has no LICENSE.txt" % pack)


## A texture is worn by a model of its folder when the model names it, or when it is called after the model
## (Knight_knight_texture.png is Knight's).
func _is_worn_by_a_model(texture: String) -> bool:
	var models: Dictionary = _models_by_folder.get(texture.get_base_dir(), {})
	var texture_in_hex := texture.get_file().get_basename().to_utf8_buffer().hex_encode()
	for model: String in models:
		if texture.get_file().begins_with(model.get_basename() + "_") or models[model].contains(texture_in_hex):
			return true
	return false


## Every file of the packs that is game content, with its full resource path.
func _asset_files() -> Array[String]:
	var files: Array[String] = []
	_collect(ASSETS, files)
	return files


func _collect(folder: String, into: Array[String]) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() not in NOT_CONTENT_EXTENSIONS:
			into.append("%s/%s" % [folder, file])
	for sub in DirAccess.get_directories_at(folder):
		_collect("%s/%s" % [folder, sub], into)


func _text_of_all(folder: String, extensions: Array) -> String:
	var text := ""
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in extensions:
			text += FileAccess.get_file_as_string("%s/%s" % [folder, file]) + "\n"
	for sub in DirAccess.get_directories_at(folder):
		text += _text_of_all("%s/%s" % [folder, sub], extensions)
	return text
