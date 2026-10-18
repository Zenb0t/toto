class_name WeaponModel
extends RefCounted
## The model of a weapon, for a hand or the floor: a KayKit weapon, or one built from parts (the bow).


static func instance(weapon_id: String) -> Node3D:
	if weapon_id == "bow":
		return BowModel.build()
	return load(CharacterLook.WEAPONS_PATH % CharacterLook.weapon_model(weapon_id)).instantiate()


## Whether the weapon has a model to show at all (fists have none).
static func has_model(weapon_id: String) -> bool:
	return CharacterLook.weapon_model(weapon_id) != CharacterLook.BARE_HANDS


## Whether the weapon is a model file the assets hold (rather than built from parts, or no model at all).
static func is_asset(weapon_id: String) -> bool:
	var model_name := CharacterLook.weapon_model(weapon_id)
	return model_name != CharacterLook.BARE_HANDS and weapon_id != "bow"
