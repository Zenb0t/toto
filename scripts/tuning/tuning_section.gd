class_name TuningSection
extends RefCounted
## One entry of the Tune screen's menu: a title and the knob groups under it (see Tuning.Param.group).
## A section with one group opens straight onto its knobs; one with several (every weapon, every potion...)
## first lists them.

var title: String
var groups: Array[String]
var _labels := {}  # group -> what its menu entry says, when not the group itself


func _init(section_title: String, section_groups: Array[String], labels := {}) -> void:
	title = section_title
	groups = section_groups
	_labels = labels


func has_submenu() -> bool:
	return groups.size() > 1


## What the group's entry in the section's menu says.
func label_of(group: String) -> String:
	return _labels.get(group, group)
